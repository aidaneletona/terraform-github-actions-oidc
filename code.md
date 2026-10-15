  plan-dev:
    needs: changes
    if: |
      !cancelled() &&
      github.ref == 'refs/heads/main' &&
      (
        github.event_name == 'schedule' ||
        (
          github.event_name == 'workflow_dispatch' &&
          (inputs.action == 'plan-dev' || inputs.action == 'apply-dev')
        ) ||
        (
          github.event_name == 'push' &&
          needs.changes.result == 'success' &&
          (
            needs.changes.outputs.dev == 'true' ||
            needs.changes.outputs.modules == 'true'
          )
        )
      )

    runs-on: ubuntu-latest

    outputs:
      exit_code: ${{ steps.plan.outputs.exit_code }}
      terraform_version: ${{ steps.version.outputs.version }}
      artifact_id: ${{ steps.saved_plan.outputs.artifact-id }}

    defaults:
      run:
        working-directory: terraform/environments/dev

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.sha }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false

      - name: Record Terraform version
        id: version
        run: |
          VERSION=$(terraform version -json | jq -r '.terraform_version')
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Configure Plan Role
        uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::523109312572:role/GitHubActionsTerraformPlanRole
          aws-region: us-east-2

      - name: Terraform Format Check DEV
        if: github.event_name != 'schedule'
        run: terraform fmt -check -recursive

      - name: Terraform Format Check MODULES
        if: github.event_name != 'schedule'
        working-directory: terraform/modules
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init -input=false

      - name: Terraform Validate
        if: github.event_name != 'schedule'
        run: terraform validate

      - name: Checkov Security Scan DEV
        if: github.event_name != 'schedule'
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/environments/dev
          framework: terraform

      - name: Clear saved Checkov results
        if: ${{ !cancelled() && github.event_name != 'schedule' }}
        run: echo "CHECKOV_RESULTS=" >> "$GITHUB_ENV"

      - name: Terraform Plan
        id: plan
        shell: bash
        run: |
          set +e
          terraform plan -input=false -no-color -lock-timeout=5m \
            -detailed-exitcode -out=tfplan
          EXIT_CODE=$?
          set -e

          echo "exit_code=$EXIT_CODE" >> "$GITHUB_OUTPUT"

          if [ "$EXIT_CODE" -eq 0 ]; then
            echo "No DEV changes detected."
          elif [ "$EXIT_CODE" -eq 2 ]; then
            echo "DEV changes detected."
          else
            echo "DEV Terraform plan failed."
            exit 1
          fi

      - name: DEV Plan Summary
        if: ${{ !cancelled() }}
        env:
          PLAN_EXIT_CODE: ${{ steps.plan.outputs.exit_code }}
          RUN_EVENT: ${{ github.event_name }}
          RUN_COMMIT: ${{ github.sha }}
        run: |
          echo "## DEV Terraform Plan" >> "$GITHUB_STEP_SUMMARY"
          echo "Commit: $RUN_COMMIT" >> "$GITHUB_STEP_SUMMARY"

          if [ "$PLAN_EXIT_CODE" = "2" ]; then
            echo "Changes detected. Review the Terraform Plan step." >> "$GITHUB_STEP_SUMMARY"
          elif [ "$PLAN_EXIT_CODE" = "0" ]; then
            echo "No changes detected." >> "$GITHUB_STEP_SUMMARY"
          else
            echo "Plan failed or did not run. Apply is blocked." >> "$GITHUB_STEP_SUMMARY"
          fi

          if [ "$RUN_EVENT" = "schedule" ]; then
            echo "Scheduled drift check: Apply is disabled." >> "$GITHUB_STEP_SUMMARY"
          fi

      - name: Scheduled Checkov Security Scan DEV
        if: ${{ !cancelled() && github.event_name == 'schedule' }}
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/environments/dev
          framework: terraform

      - name: Clear saved Checkov results
        if: ${{ !cancelled() && github.event_name == 'schedule' }}
        run: echo "CHECKOV_RESULTS=" >> "$GITHUB_ENV"

      - name: Upload saved plan
        if: github.event_name != 'schedule'
        id: saved_plan
        uses: actions/upload-artifact@v4
        with:
          name: dev-plan-${{ github.run_id }}-${{ github.run_attempt }}
          path: |
            terraform/environments/dev/tfplan
            terraform/environments/dev/.terraform.lock.hcl
          include-hidden-files: true
          if-no-files-found: error
          retention-days: 3


  apply-dev:
    needs: plan-dev
    if: |
      !cancelled() &&
      needs['plan-dev'].result == 'success' &&
      github.ref == 'refs/heads/main' &&
      (
        needs['plan-dev'].outputs.exit_code == '0' ||
        needs['plan-dev'].outputs.exit_code == '2'
      ) &&
      (
        github.event_name == 'push' ||
        (
          github.event_name == 'workflow_dispatch' &&
          inputs.action == 'apply-dev'
        )
      )

    environment: dev
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: terraform/environments/dev

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.sha }}

      - name: Setup the same Terraform version used for Plan
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ needs['plan-dev'].outputs.terraform_version }}
          terraform_wrapper: false

      - name: Download saved DEV plan
        uses: actions/download-artifact@v4
        with:
          artifact-ids: ${{ needs['plan-dev'].outputs.artifact_id }}
          path: terraform/environments/dev
          merge-multiple: true

      - name: Configure Apply Role
        uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::523109312572:role/GitHubActionsTerraformApplyRole
          aws-region: us-east-2

      - name: Terraform Init
        run: terraform init -input=false -lockfile=readonly

      - name: Terraform Apply saved plan
        if: needs['plan-dev'].outputs.exit_code == '2'
        run: terraform apply -input=false -no-color -lock-timeout=5m tfplan

      - name: Verify saved no-change plan
        if: needs['plan-dev'].outputs.exit_code == '0'
        run: terraform apply -input=false -no-color -lock-timeout=5m tfplan

      - name: Record module version verified in DEV
        shell: bash
        run: |
          set -euo pipefail

          git rev-parse HEAD:terraform/modules \
            > "$RUNNER_TEMP/dev-modules-version"

          aws s3 cp \
            "$RUNNER_TEMP/dev-modules-version" \
            s3://terraform-oidc-state-aidan/dev/last-applied-modules


  plan-prod:
    needs:
      - changes
      - apply-dev

    if: |
      !cancelled() &&
      github.ref == 'refs/heads/main' &&
      (
        github.event_name == 'schedule' ||
        (
          github.event_name == 'workflow_dispatch' &&
          (inputs.action == 'plan-prod' || inputs.action == 'apply-prod')
        ) ||
        (
          github.event_name == 'push' &&
          needs.changes.result == 'success' &&
          (
            needs.changes.outputs.prod == 'true' ||
            needs.changes.outputs.modules == 'true'
          ) &&
          (
            needs.changes.outputs.modules != 'true' ||
            needs['apply-dev'].result == 'success'
          )
        )
      )

    runs-on: ubuntu-latest

    outputs:
      exit_code: ${{ steps.plan.outputs.exit_code }}
      terraform_version: ${{ steps.version.outputs.version }}
      artifact_id: ${{ steps.saved_plan.outputs.artifact-id }}

    defaults:
      run:
        working-directory: terraform/environments/prod

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.sha }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false

      - name: Record Terraform version
        id: version
        run: |
          VERSION=$(terraform version -json | jq -r '.terraform_version')
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Configure Plan Role
        uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::523109312572:role/GitHubActionsTerraformPlanRole
          aws-region: us-east-2

      - name: Terraform Format Check PROD
        if: github.event_name != 'schedule'
        run: terraform fmt -check -recursive

      - name: Terraform Format Check MODULES
        if: github.event_name != 'schedule'
        working-directory: terraform/modules
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init -input=false

      - name: Terraform Validate
        if: github.event_name != 'schedule'
        run: terraform validate

      - name: Checkov Security Scan PROD
        if: github.event_name != 'schedule'
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/environments/prod
          framework: terraform

      - name: Clear saved Checkov results
        if: ${{ !cancelled() && github.event_name != 'schedule' }}
        run: echo "CHECKOV_RESULTS=" >> "$GITHUB_ENV"

      - name: Terraform Plan
        id: plan
        shell: bash
        run: |
          set +e
          terraform plan -input=false -no-color -lock-timeout=5m \
            -detailed-exitcode -out=tfplan
          EXIT_CODE=$?
          set -e

          echo "exit_code=$EXIT_CODE" >> "$GITHUB_OUTPUT"

          if [ "$EXIT_CODE" -eq 0 ]; then
            echo "No PROD changes detected."
          elif [ "$EXIT_CODE" -eq 2 ]; then
            echo "PROD changes detected."
          else
            echo "PROD Terraform plan failed."
            exit 1
          fi

      - name: PROD Plan Summary
        if: ${{ !cancelled() }}
        env:
          PLAN_EXIT_CODE: ${{ steps.plan.outputs.exit_code }}
          RUN_EVENT: ${{ github.event_name }}
          RUN_COMMIT: ${{ github.sha }}
        run: |
          echo "## PROD Terraform Plan" >> "$GITHUB_STEP_SUMMARY"
          echo "Commit: $RUN_COMMIT" >> "$GITHUB_STEP_SUMMARY"

          if [ "$PLAN_EXIT_CODE" = "2" ]; then
            echo "Changes detected. Review the Terraform Plan step." >> "$GITHUB_STEP_SUMMARY"
          elif [ "$PLAN_EXIT_CODE" = "0" ]; then
            echo "No changes detected." >> "$GITHUB_STEP_SUMMARY"
          else
            echo "Plan failed or did not run. Apply is blocked." >> "$GITHUB_STEP_SUMMARY"
          fi

          if [ "$RUN_EVENT" = "schedule" ]; then
            echo "Scheduled drift check: Apply is disabled." >> "$GITHUB_STEP_SUMMARY"
          fi

      - name: Scheduled Checkov Security Scan PROD
        if: ${{ !cancelled() && github.event_name == 'schedule' }}
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/environments/prod
          framework: terraform

      - name: Clear saved Checkov results
        if: ${{ !cancelled() && github.event_name == 'schedule' }}
        run: echo "CHECKOV_RESULTS=" >> "$GITHUB_ENV"

      - name: Upload saved plan
        if: github.event_name != 'schedule'
        id: saved_plan
        uses: actions/upload-artifact@v4
        with:
          name: prod-plan-${{ github.run_id }}-${{ github.run_attempt }}
          path: |
            terraform/environments/prod/tfplan
            terraform/environments/prod/.terraform.lock.hcl
          include-hidden-files: true
          if-no-files-found: error
          retention-days: 3


  apply-prod:
    needs: plan-prod
    if: |
      always() && !cancelled() &&
      needs['plan-prod'].result == 'success' &&
      github.ref == 'refs/heads/main' &&
      needs['plan-prod'].outputs.exit_code == '2' &&
      (
        github.event_name == 'push' ||
        (
          github.event_name == 'workflow_dispatch' &&
          inputs.action == 'apply-prod'
        )
      )

    environment: prod
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: terraform/environments/prod

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.sha }}

      - name: Setup the same Terraform version used for Plan
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ needs['plan-prod'].outputs.terraform_version }}
          terraform_wrapper: false

      - name: Download saved PROD plan
        uses: actions/download-artifact@v4
        with:
          artifact-ids: ${{ needs['plan-prod'].outputs.artifact_id }}
          path: terraform/environments/prod
          merge-multiple: true

      - name: Configure Plan Role
        uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::523109312572:role/GitHubActionsTerraformPlanRole
          aws-region: us-east-2

      - name: Verify current modules succeeded in DEV
        shell: bash
        run: |
          set -euo pipefail

          aws s3 cp \
            s3://terraform-oidc-state-aidan/dev/last-applied-modules \
            "$RUNNER_TEMP/dev-modules-version"

          dev_version="$(cat "$RUNNER_TEMP/dev-modules-version")"
          current_version="$(git rev-parse HEAD:terraform/modules)"

          if [ "$current_version" != "$dev_version" ]; then
            echo "Current modules have not succeeded in DEV. Blocking PROD apply."
            exit 1
          fi

          echo "Current modules match the version verified in DEV."

      - name: Configure Apply Role
        uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::523109312572:role/GitHubActionsTerraformApplyRole
          aws-region: us-east-2

      - name: Terraform Init
        run: terraform init -input=false -lockfile=readonly

      - name: Terraform Apply saved plan
        run: terraform apply -input=false -no-color -lock-timeout=5m tfplan