import XCTest
@testable import SysmCore

final class WorkflowEngineTests: XCTestCase {
    var engine: WorkflowEngine!

    override func setUp() {
        super.setUp()
        engine = WorkflowEngine()
    }

    // MARK: - parse(yaml:)

    func testParseMinimalValid() throws {
        let yaml = """
        name: test
        steps:
          - name: step1
            run: echo hello
        """
        let workflow = try engine.parse(yaml: yaml)
        XCTAssertEqual(workflow.name, "test")
        XCTAssertEqual(workflow.steps.count, 1)
        XCTAssertEqual(workflow.steps[0].name, "step1")
        XCTAssertEqual(workflow.steps[0].run, "echo hello")
    }

    func testParseFullWorkflow() throws {
        let yaml = """
        name: full-workflow
        description: A complete workflow
        version: "2.0.0"
        author: tester
        env:
          MY_VAR: hello
        steps:
          - name: step1
            run: echo $MY_VAR
            output: result
            timeout: 30
          - name: step2
            run: echo {{ result }}
            when: "true"
            continue_on_error: true
            retries: 3
            retry_delay: 2
        on_error:
          - notify: admin
        """
        let workflow = try engine.parse(yaml: yaml)
        XCTAssertEqual(workflow.name, "full-workflow")
        XCTAssertEqual(workflow.description, "A complete workflow")
        XCTAssertEqual(workflow.version, "2.0.0")
        XCTAssertEqual(workflow.author, "tester")
        XCTAssertEqual(workflow.env?["MY_VAR"], "hello")
        XCTAssertEqual(workflow.steps.count, 2)
        XCTAssertEqual(workflow.steps[0].output, "result")
        XCTAssertEqual(workflow.steps[0].timeout, 30)
        XCTAssertEqual(workflow.steps[1].continueOnError, true)
        XCTAssertEqual(workflow.steps[1].retries, 3)
        XCTAssertEqual(workflow.steps[1].retryDelay, 2)
        XCTAssertEqual(workflow.onError?.count, 1)
    }

    func testParseInvalidYAML() {
        let yaml = "{{{{invalid yaml}}}}}}::::"
        XCTAssertThrowsError(try engine.parse(yaml: yaml)) { error in
            guard case WorkflowError.parseError = error else {
                XCTFail("Expected parseError, got \(error)")
                return
            }
        }
    }

    func testParseMissingRequiredFields() {
        // Missing 'name' should fail since Workflow requires it
        let yaml = """
        steps:
          - name: step1
            run: echo hello
        """
        XCTAssertThrowsError(try engine.parse(yaml: yaml))
    }

    // MARK: - validate()

    func testValidateValidWorkflow() throws {
        let workflow = Workflow(
            name: "valid",
            steps: [WorkflowStep(name: "step1", run: "echo hello")]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertTrue(result.valid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testValidateEmptyName() {
        let workflow = Workflow(
            name: "",
            steps: [WorkflowStep(name: "step1", run: "echo hello")]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.errors.contains("Workflow name is required"))
    }

    func testValidateEmptySteps() {
        let workflow = Workflow(name: "test", steps: [])
        let result = engine.validate(workflow: workflow)
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.errors.contains("Workflow must have at least one step"))
    }

    func testValidateEmptyStepName() {
        let workflow = Workflow(
            name: "test",
            steps: [WorkflowStep(name: "", run: "echo hello")]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.errors.contains { $0.contains("must have a name") })
    }

    func testValidateEmptyStepRun() {
        let workflow = Workflow(
            name: "test",
            steps: [WorkflowStep(name: "step1", run: "")]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.errors.contains { $0.contains("must have a 'run' command") })
    }

    func testValidateDuplicateStepNames() {
        let workflow = Workflow(
            name: "test",
            steps: [
                WorkflowStep(name: "dupe", run: "echo 1"),
                WorkflowStep(name: "dupe", run: "echo 2"),
            ]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertFalse(result.valid)
        XCTAssertTrue(result.errors.contains { $0.contains("Duplicate step name") })
    }

    func testValidateNegativeTimeout() {
        let workflow = Workflow(
            name: "test",
            steps: [WorkflowStep(name: "step1", run: "echo hello", timeout: -1)]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertTrue(result.valid) // Warnings don't invalidate
        XCTAssertTrue(result.warnings.contains { $0.contains("invalid timeout") })
    }

    func testValidateNegativeRetries() {
        let workflow = Workflow(
            name: "test",
            steps: [WorkflowStep(name: "step1", run: "echo hello", retries: -1)]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertTrue(result.valid)
        XCTAssertTrue(result.warnings.contains { $0.contains("invalid retries") })
    }

    func testValidateOutputVarWithSpaces() {
        let workflow = Workflow(
            name: "test",
            steps: [WorkflowStep(name: "step1", run: "echo hi", output: "my var")]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertTrue(result.warnings.contains { $0.contains("spaces or dashes") })
    }

    func testValidateUndefinedVariableReference() {
        let workflow = Workflow(
            name: "test",
            steps: [WorkflowStep(name: "step1", run: "echo {{ missing }}")]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertTrue(result.warnings.contains { $0.contains("undefined variable") })
    }

    func testValidateVariableFromPriorStep() {
        let workflow = Workflow(
            name: "test",
            steps: [
                WorkflowStep(name: "step1", run: "echo hello", output: "greeting"),
                WorkflowStep(name: "step2", run: "echo {{ greeting }}"),
            ]
        )
        let result = engine.validate(workflow: workflow)
        // greeting is defined by step1, so no warning
        XCTAssertFalse(result.warnings.contains { $0.contains("undefined variable 'greeting'") })
    }

    func testValidateVariableFromEnv() {
        let workflow = Workflow(
            name: "test",
            env: ["MY_VAR": "hello"],
            steps: [WorkflowStep(name: "step1", run: "echo {{ MY_VAR }}")]
        )
        let result = engine.validate(workflow: workflow)
        XCTAssertFalse(result.warnings.contains { $0.contains("undefined variable 'MY_VAR'") })
    }

    // MARK: - run(dryRun: true)

    func testDryRunReturnsPrefix() throws {
        let workflow = Workflow(
            name: "dry-test",
            steps: [WorkflowStep(name: "step1", run: "echo hello")]
        )
        let result = try engine.run(workflow: workflow, dryRun: true)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.steps.count, 1)
        XCTAssertTrue(result.steps[0].stdout.contains("[dry-run]"))
        XCTAssertTrue(result.steps[0].stdout.contains("echo hello"))
    }

    func testDryRunSkipsConditionFalse() throws {
        let workflow = Workflow(
            name: "cond-test",
            steps: [
                WorkflowStep(name: "step1", run: "echo hello", when: "false"),
            ]
        )
        let result = try engine.run(workflow: workflow, dryRun: true)
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.steps[0].skipped)
    }

    func testDryRunConditionTrue() throws {
        let workflow = Workflow(
            name: "cond-test",
            steps: [
                WorkflowStep(name: "step1", run: "echo hello", when: "true"),
            ]
        )
        let result = try engine.run(workflow: workflow, dryRun: true)
        XCTAssertFalse(result.steps[0].skipped)
    }

    func testDryRunMultipleSteps() throws {
        let workflow = Workflow(
            name: "multi",
            steps: [
                WorkflowStep(name: "s1", run: "echo 1"),
                WorkflowStep(name: "s2", run: "echo 2"),
                WorkflowStep(name: "s3", run: "echo 3"),
            ]
        )
        let result = try engine.run(workflow: workflow, dryRun: true)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.steps.count, 3)
    }

    // MARK: - Real execution (simple)

    func testRunSimpleEcho() throws {
        let workflow = Workflow(
            name: "echo-test",
            steps: [WorkflowStep(name: "greet", run: "echo hello")]
        )
        let result = try engine.run(workflow: workflow)
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.steps[0].stdout.contains("hello"))
    }

    func testRunFailingStep() throws {
        let workflow = Workflow(
            name: "fail-test",
            steps: [WorkflowStep(name: "fail", run: "exit 1")]
        )
        let result = try engine.run(workflow: workflow)
        XCTAssertFalse(result.success)
        XCTAssertFalse(result.steps[0].success)
    }

    func testRunContinueOnError() throws {
        let workflow = Workflow(
            name: "continue-test",
            steps: [
                WorkflowStep(name: "fail", run: "exit 1", continueOnError: true),
                WorkflowStep(name: "pass", run: "echo ok"),
            ]
        )
        let result = try engine.run(workflow: workflow)
        // Overall success is false because allSatisfy checks success||skipped
        // but continueOnError prevents early exit, so both steps run
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.steps.count, 2)
        XCTAssertFalse(result.steps[0].success)
        XCTAssertTrue(result.steps[1].success)
        XCTAssertNil(result.error) // no lastError because continueOnError
    }
}
