import { expect } from "vitest";
import {
  accessGuardsOf,
  requiredLocation,
} from "../gateway-location-support";
import {
  FAR_FUTURE,
  LONG_PAST,
  PREFLIGHT_METHOD,
  POST_METHOD,
  VERIFIED_AUTHORIZATION,
  type FakeRequest,
  bearerAuthorization,
  protectedGuardAnswers,
  publicGuardAnswers,
  requestUsing,
  requestWith,
  signedWith,
} from "../jwt-support";
import {
  AUTHENTICATION_ZONE_WORD,
  CLIENT_ADDRESS_BYTES,
  GENERATION_COST_ZONE_WORD,
  GENERATION_WATCHER_POLL,
  evaluatedKey,
  requiredZone,
} from "../rate-limit-support";

export type GatewayWorld = {
  answers: unknown[][];
};

type StepAction = (world: GatewayWorld, values: readonly string[]) => void;

type StepDefinition = {
  readonly keyword: string;
  readonly pattern: RegExp;
  readonly action: StepAction;
};

const FORGING_SECRET = "a secret the gateway never signed with";
const BYTES_PER_MEGABYTE = 1024 * 1024;
const CHUNKED_TRANSFER = "chunked";
const LOGIN_ROUTE = "/api/user/login";
const GENERATION_ROUTE = "/api/content/generate-study-units";
const PER_MINUTE_SUFFIX = "r/m";
const GUARD_NAMES: Readonly<Record<string, string>> = {
  protected: "jwt.guardProtectedRoute",
  public: "jwt.guardPublicRoute",
};

function signedRequest(claims: Record<string, unknown>, secret?: string) {
  return requestWith(bearerAuthorization(signedWith(claims, secret)));
}

function guardedAnswers(routeKind: string, request: FakeRequest) {
  if (routeKind === "public") {
    return publicGuardAnswers(request);
  }

  return protectedGuardAnswers(request);
}

function uploadDeclaring(megabytes: number): FakeRequest {
  const request = requestWith(VERIFIED_AUTHORIZATION);
  const declaredBytes = megabytes * BYTES_PER_MEGABYTE;

  request.headersIn["Content-Length"] = String(declaredBytes);

  return request;
}

function chunkedUpload(): FakeRequest {
  const request = requestWith(VERIFIED_AUTHORIZATION);

  request.headersIn["Transfer-Encoding"] = CHUNKED_TRANSFER;

  return request;
}

function checkPerMinuteLimit(zoneWord: string, route: string, count: string) {
  expect(requiredZone(zoneWord).rateText).toBe(count + PER_MINUTE_SUFFIX);
  expect(evaluatedKey(zoneWord, route)).toContain(CLIENT_ADDRESS_BYTES);
}

function checkAnswer(world: GatewayWorld, values: readonly string[]): void {
  expect(world.answers).toEqual([[Number(values[0])]]);
}

export const gatewayStepDefinitions: readonly StepDefinition[] = [
  {
    keyword: "When",
    pattern: /^a content request reaches the gateway without a sign-in$/,
    action: (world) => {
      world.answers = protectedGuardAnswers(requestWith());
    },
  },
  {
    keyword: "When",
    pattern: /^a content request reaches the gateway with a forged sign-in$/,
    action: (world) => {
      const forged = signedRequest({ exp: FAR_FUTURE }, FORGING_SECRET);
      world.answers = protectedGuardAnswers(forged);
    },
  },
  {
    keyword: "When",
    pattern: /^a content request reaches the gateway with an expired sign-in$/,
    action: (world) => {
      world.answers = protectedGuardAnswers(signedRequest({ exp: LONG_PAST }));
    },
  },
  {
    keyword: "When",
    pattern: /^a content request reaches the gateway with a valid sign-in$/,
    action: (world) => {
      const valid = requestWith(VERIFIED_AUTHORIZATION);
      world.answers = protectedGuardAnswers(valid);
    },
  },
  {
    keyword: "When",
    pattern: /^a sign-up request reaches the gateway without a sign-in$/,
    action: (world) => {
      world.answers = publicGuardAnswers(requestUsing(POST_METHOD));
    },
  },
  {
    keyword: "When",
    pattern: /^a preflight request reaches a (protected|public) route$/,
    action: (world, values) => {
      const preflight = requestUsing(PREFLIGHT_METHOD);
      world.answers = guardedAnswers(String(values[0]), preflight);
    },
  },
  {
    keyword: "When",
    pattern: /^a content upload declaring (\d+) MB reaches the gateway$/,
    action: (world, values) => {
      const upload = uploadDeclaring(Number(values[0]));
      world.answers = protectedGuardAnswers(upload);
    },
  },
  {
    keyword: "When",
    pattern: /^a chunked content upload without a length reaches the gateway$/,
    action: (world) => {
      world.answers = protectedGuardAnswers(chunkedUpload());
    },
  },
  {
    keyword: "Then",
    pattern: /^the gateway refuses it with (\d+)$/,
    action: checkAnswer,
  },
  {
    keyword: "Then",
    pattern: /^the gateway answers it with (\d+)$/,
    action: checkAnswer,
  },
  {
    keyword: "Then",
    pattern: /^the gateway passes it on$/,
    action: (world) => {
      expect(world.answers).toEqual([]);
    },
  },
  {
    keyword: "Then",
    pattern: /^the gateway guards "(.+)" as a (protected|public) route$/,
    action: (_world, values) => {
      const location = requiredLocation(String(values[0]));
      const guardName = GUARD_NAMES[String(values[1])];

      expect(accessGuardsOf(location)).toEqual([guardName]);
    },
  },
  {
    keyword: "Then",
    pattern: /^sign-in attempts are limited to (\d+) a minute per client$/,
    action: (_world, values) => {
      const count = String(values[0]);
      checkPerMinuteLimit(AUTHENTICATION_ZONE_WORD, LOGIN_ROUTE, count);
    },
  },
  {
    keyword: "Then",
    pattern: /^generation requests are limited to (\d+) a minute per client$/,
    action: (_world, values) => {
      const count = String(values[0]);
      checkPerMinuteLimit(GENERATION_COST_ZONE_WORD, GENERATION_ROUTE, count);
    },
  },
  {
    keyword: "Then",
    pattern: /^checking on a generation is not counted as a generation$/,
    action: () => {
      const pollKey = evaluatedKey(
        GENERATION_COST_ZONE_WORD,
        GENERATION_WATCHER_POLL,
      );

      expect(pollKey).toBe("");
    },
  },
];
