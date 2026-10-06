// Validates every GraphQL document in a tracker file against the vendor schema (graphql-js validate()). tests/tracker-apis/run.sh runs it.
// Validates every GraphQL document in a tracker file against the vendor's official schema (graphql-js validate()).
const { buildSchema, parse, validate } = require("graphql");
const fs = require("fs");
const [schemaFile, src] = process.argv.slice(2);
const schema = buildSchema(fs.readFileSync(schemaFile, "utf8"), { assumeValidSDL: true });
const code = fs.readFileSync(src, "utf8");
// the documents: backtick strings that start with query/mutation; ${…} pieces are expanded the way the code does
let docs = [...code.matchAll(/`((?:query|mutation)[^`]*)`/g)].map((m) => m[1]);
const fieldsPiece = (code.match(/const fields = `([^`]*)`/) || [])[1];
docs = docs.flatMap((d) => d.includes("${who}") ? ["organization", "user"].map((w) => d.replace("${who}", w).replace("${fields}", fieldsPiece)) : [d]);
let bad = 0;
for (const d of docs) {
  const errs = validate(schema, parse(d));
  console.log(`${errs.length ? "FAIL" : "ok  "} ${d.replace(/\s+/g, " ").slice(0, 110)}`);
  for (const e of errs) { console.log("      " + e.message); bad++; }
}
process.exit(bad ? 1 : 0);
