import fs from "fs";
import { describe, expect, test } from "vitest";
import {
  GATEWAY_TAG,
  type GherkinScenario,
  type GherkinStep,
  scenariosTagged,
} from "./gherkin-scenarios";
import {
  type GatewayWorld,
  gatewayStepDefinitions,
} from "./gateway-steps";
import { signInStepDefinitions } from "./sign-in-steps";

const REQUIREMENTS_DIRECTORY = "../../../requirements";
const FEATURE_SUFFIX = ".feature";

function gatewayScenarios(): readonly GherkinScenario[] {
  const scenarios: GherkinScenario[] = [];
  const featureNames = fs
    .readdirSync(REQUIREMENTS_DIRECTORY)
    .map(String)
    .filter((name) => name.endsWith(FEATURE_SUFFIX))
    .sort();

  for (const featureName of featureNames) {
    const featurePath = `${REQUIREMENTS_DIRECTORY}/${featureName}`;
    const featureText = fs.readFileSync(featurePath, "utf8");
    scenarios.push(...scenariosTagged(featureText, GATEWAY_TAG));
  }

  return scenarios;
}

function runStep(world: GatewayWorld, step: GherkinStep): void {
  const definitions = [...gatewayStepDefinitions, ...signInStepDefinitions];

  for (const definition of definitions) {
    if (definition.keyword !== step.keyword) {
      continue;
    }

    const match = definition.pattern.exec(step.text);

    if (match !== null) {
      definition.action(world, match.slice(1));
      return;
    }
  }

  throw new Error(`No step definition for "${step.keyword} ${step.text}"`);
}

const scenarios = gatewayScenarios();

describe("gateway requirements", () => {
  test("the requirements folder holds gateway scenarios", () => {
    expect(scenarios.length).toBeGreaterThan(0);
  });

  for (const scenario of scenarios) {
    test(scenario.name, () => {
      const world: GatewayWorld = { answers: [], errors: [] };

      for (const step of scenario.steps) {
        runStep(world, step);
      }
    });
  }
});
