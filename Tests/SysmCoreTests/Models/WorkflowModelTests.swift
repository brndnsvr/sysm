import XCTest
@testable import SysmCore

final class WorkflowModelTests: XCTestCase {

    // MARK: - Workflow Codable Round-trip

    func testWorkflowCodableRoundTrip() throws {
        let original = Workflow(
            name: "test-workflow",
            description: "A test workflow",
            version: "1.0.0",
            author: "tester",
            triggers: [WorkflowTrigger(schedule: "0 9 * * *", manual: true)],
            env: ["KEY": "value"],
            steps: [
                WorkflowStep(name: "step1", run: "echo hello", output: "greeting"),
                WorkflowStep(name: "step2", run: "echo {{ greeting }}", when: "true"),
            ],
            onError: [WorkflowErrorHandler(notify: "admin", run: "echo failed")]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(Workflow.self, from: data)

        XCTAssertEqual(decoded.name, "test-workflow")
        XCTAssertEqual(decoded.description, "A test workflow")
        XCTAssertEqual(decoded.version, "1.0.0")
        XCTAssertEqual(decoded.author, "tester")
        XCTAssertEqual(decoded.triggers?.count, 1)
        XCTAssertEqual(decoded.env?["KEY"], "value")
        XCTAssertEqual(decoded.steps.count, 2)
        XCTAssertEqual(decoded.onError?.count, 1)
    }

    // MARK: - WorkflowStep CodingKeys

    func testWorkflowStepSnakeCaseCodingKeys() throws {
        let json = """
        {
            "name": "test",
            "run": "echo hello",
            "continue_on_error": true,
            "retry_delay": 10
        }
        """
        let step = try JSONDecoder().decode(WorkflowStep.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(step.continueOnError, true)
        XCTAssertEqual(step.retryDelay, 10)
    }

    func testWorkflowStepEncodesToSnakeCase() throws {
        let step = WorkflowStep(
            name: "test", run: "echo",
            continueOnError: true, retryDelay: 5
        )
        let data = try JSONEncoder().encode(step)
        let jsonString = String(data: data, encoding: .utf8)!
        XCTAssertTrue(jsonString.contains("continue_on_error"))
        XCTAssertTrue(jsonString.contains("retry_delay"))
    }

    // MARK: - WorkflowStepResult.skipped()

    func testSkippedFactory() {
        let result = WorkflowStepResult.skipped(name: "skip-me")
        XCTAssertEqual(result.name, "skip-me")
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout, "")
        XCTAssertEqual(result.stderr, "")
        XCTAssertEqual(result.duration, 0)
        XCTAssertTrue(result.skipped)
    }

    // MARK: - WorkflowResult.formatted()

    func testFormattedSuccess() {
        let result = WorkflowResult(
            workflow: "my-workflow",
            success: true,
            totalDuration: 1.23,
            steps: [
                WorkflowStepResult(name: "step1", success: true, exitCode: 0, stdout: "ok", stderr: "", duration: 0.5, skipped: false),
                WorkflowStepResult(name: "step2", success: true, exitCode: 0, stdout: "done", stderr: "", duration: 0.7, skipped: false),
            ],
            error: nil
        )

        let output = result.formatted()
        XCTAssertTrue(output.contains("my-workflow"))
        XCTAssertTrue(output.contains("SUCCESS"))
        XCTAssertTrue(output.contains("1.23s"))
        XCTAssertTrue(output.contains("2/2"))
    }

    func testFormattedFailure() {
        let result = WorkflowResult(
            workflow: "broken",
            success: false,
            totalDuration: 0.5,
            steps: [
                WorkflowStepResult(name: "fail-step", success: false, exitCode: 1, stdout: "", stderr: "error!", duration: 0.5, skipped: false),
            ],
            error: "Step 'fail-step' failed"
        )

        let output = result.formatted()
        XCTAssertTrue(output.contains("FAILED"))
        XCTAssertTrue(output.contains("stderr: error!"))
        XCTAssertTrue(output.contains("Step 'fail-step' failed"))
    }

    func testFormattedVerbose() {
        let result = WorkflowResult(
            workflow: "verbose-wf",
            success: true,
            totalDuration: 2.0,
            steps: [
                WorkflowStepResult(name: "step1", success: true, exitCode: 0, stdout: "output here", stderr: "", duration: 1.0, skipped: false),
                WorkflowStepResult.skipped(name: "step2"),
            ],
            error: nil
        )

        let output = result.formatted(verbose: true)
        XCTAssertTrue(output.contains("stdout: output here"))
        XCTAssertTrue(output.contains("SKIPPED"))
    }

    func testFormattedSkippedStepCount() {
        let result = WorkflowResult(
            workflow: "wf",
            success: true,
            totalDuration: 1.0,
            steps: [
                WorkflowStepResult(name: "run", success: true, exitCode: 0, stdout: "", stderr: "", duration: 0.5, skipped: false),
                WorkflowStepResult.skipped(name: "skip"),
            ],
            error: nil
        )

        let output = result.formatted()
        XCTAssertTrue(output.contains("Steps: 1/2"))
    }

    // MARK: - WorkflowValidationResult.formatted()

    func testValidationFormattedValid() {
        let result = WorkflowValidationResult(valid: true, errors: [], warnings: [])
        let output = result.formatted()
        XCTAssertTrue(output.contains("Workflow is valid"))
    }

    func testValidationFormattedWithErrors() {
        let result = WorkflowValidationResult(
            valid: false,
            errors: ["Name is empty", "No steps"],
            warnings: []
        )
        let output = result.formatted()
        XCTAssertTrue(output.contains("Workflow has errors"))
        XCTAssertTrue(output.contains("ERROR: Name is empty"))
        XCTAssertTrue(output.contains("ERROR: No steps"))
    }

    func testValidationFormattedWithWarnings() {
        let result = WorkflowValidationResult(
            valid: true,
            errors: [],
            warnings: ["Negative timeout"]
        )
        let output = result.formatted()
        XCTAssertTrue(output.contains("WARN: Negative timeout"))
    }

    // MARK: - WorkflowError.errorDescription

    func testWorkflowErrorDescriptions() {
        XCTAssertTrue(WorkflowError.fileNotFound("/tmp/missing.yaml").errorDescription!.contains("/tmp/missing.yaml"))
        XCTAssertTrue(WorkflowError.parseError("bad yaml").errorDescription!.contains("bad yaml"))
        XCTAssertTrue(WorkflowError.stepFailed("step1", "exit 1").errorDescription!.contains("step1"))
        XCTAssertTrue(WorkflowError.conditionFailed("bad cond").errorDescription!.contains("bad cond"))
        XCTAssertTrue(WorkflowError.invalidTemplate("tmpl").errorDescription!.contains("tmpl"))
        XCTAssertTrue(WorkflowError.timeout("slow").errorDescription!.contains("slow"))
    }
}
