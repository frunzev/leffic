export const GATEWAY_TAG = "@gateway";

const FEATURE_KEYWORD = "Feature:";
const RULE_KEYWORD = "Rule:";
const SCENARIO_KEYWORD = "Scenario:";
const TAG_MARKER = "@";
const COMMENT_MARKER = "#";
const FIRST_STEP_KEYWORD = "Given";
const STEP_KEYWORDS: readonly string[] = ["Given", "When", "Then"];
const CONJUNCTIONS: readonly string[] = ["And", "But"];

export type GherkinStep = {
  readonly keyword: string;
  readonly text: string;
};

export type GherkinScenario = {
  readonly name: string;
  readonly tags: ReadonlySet<string>;
  readonly steps: readonly GherkinStep[];
};

class ScenarioReader {
  readonly scenarios: GherkinScenario[] = [];
  private pendingTags: Set<string> = new Set();
  private featureTags: Set<string> = new Set();
  private ruleTags: Set<string> = new Set();
  private scenarioName: string | null = null;
  private scenarioTags: Set<string> = new Set();
  private steps: GherkinStep[] = [];
  private lastKeyword = FIRST_STEP_KEYWORD;

  read(line: string): void {
    const text = line.trim();

    if (text === "" || text.startsWith(COMMENT_MARKER)) {
      return;
    }

    if (text.startsWith(TAG_MARKER)) {
      for (const tag of text.split(/\s+/)) {
        this.pendingTags.add(tag);
      }
    } else if (text.startsWith(FEATURE_KEYWORD)) {
      this.featureTags = this.takePendingTags();
    } else if (text.startsWith(RULE_KEYWORD)) {
      this.finishScenario();
      this.ruleTags = this.takePendingTags();
    } else if (text.startsWith(SCENARIO_KEYWORD)) {
      this.startScenario(text.slice(SCENARIO_KEYWORD.length).trim());
    } else {
      this.readStep(text);
    }
  }

  finishScenario(): void {
    if (this.scenarioName === null) {
      return;
    }

    this.scenarios.push({
      name: this.scenarioName,
      tags: this.scenarioTags,
      steps: this.steps,
    });
    this.scenarioName = null;
  }

  private takePendingTags(): Set<string> {
    const tags = this.pendingTags;
    this.pendingTags = new Set();

    return tags;
  }

  private startScenario(scenarioName: string): void {
    this.finishScenario();
    this.scenarioName = scenarioName;
    const scenarioTags = new Set<string>();
    const addTag = (tag: string) => scenarioTags.add(tag);

    this.featureTags.forEach(addTag);
    this.ruleTags.forEach(addTag);
    this.takePendingTags().forEach(addTag);
    this.scenarioTags = scenarioTags;
    this.steps = [];
    this.lastKeyword = FIRST_STEP_KEYWORD;
  }

  private readStep(text: string): void {
    const firstSpace = text.indexOf(" ");

    if (this.scenarioName === null || firstSpace < 0) {
      return;
    }

    const writtenKeyword = text.slice(0, firstSpace);
    const stepText = text.slice(firstSpace + 1).trim();

    if (CONJUNCTIONS.includes(writtenKeyword)) {
      this.steps.push({ keyword: this.lastKeyword, text: stepText });
    } else if (STEP_KEYWORDS.includes(writtenKeyword)) {
      this.lastKeyword = writtenKeyword;
      this.steps.push({ keyword: writtenKeyword, text: stepText });
    }
  }
}

export function scenariosTagged(
  featureText: string,
  tag: string,
): readonly GherkinScenario[] {
  const reader = new ScenarioReader();

  for (const line of featureText.split("\n")) {
    reader.read(line);
  }

  reader.finishScenario();

  return reader.scenarios.filter((scenario) => scenario.tags.has(tag));
}
