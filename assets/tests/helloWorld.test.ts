import { hello } from "../src/helloWorld";

describe("hello", () => {
  test("returns hello world as a string", () => {
    expect(hello()).toEqual("hello world");
  });
});
