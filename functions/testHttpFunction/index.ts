import { http } from "@google-cloud/functions-framework";

interface Body {
  name: string;
}

http('testHttpFunction', (req) => {
  console.log(`Hello, ${(req.body as Body).name}!`);
});
