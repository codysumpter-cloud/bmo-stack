#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const requiredFiles = [
  'contracts/pokemon-champions/common.schema.json',
  'contracts/pokemon-champions/format-snapshot.schema.json',
  'contracts/pokemon-champions/team-build-request.schema.json',
  'contracts/pokemon-champions/team-build-response.schema.json',
  'contracts/pokemon-champions/team-audit-request.schema.json',
  'contracts/pokemon-champions/team-audit-response.schema.json',
  'docs/api/pokemon-champions-team-builder.openapi.yaml',
];

for (const file of requiredFiles) {
  const fullPath = resolve(process.cwd(), file);
  if (!existsSync(fullPath)) {
    console.error(`Missing required Pokemon team builder contract file: ${file}`);
    process.exit(1);
  }
}

const jsonSchemas = requiredFiles.filter((file) => file.endsWith('.json'));
for (const file of jsonSchemas) {
  const fullPath = resolve(process.cwd(), file);
  const parsed = JSON.parse(readFileSync(fullPath, 'utf8'));
  if (parsed.$schema !== 'https://json-schema.org/draft/2020-12/schema') {
    console.error(`${file} must declare draft 2020-12 JSON Schema.`);
    process.exit(1);
  }
  if (parsed.type !== 'object') {
    console.error(`${file} must declare type=object.`);
    process.exit(1);
  }
}

const openApiPath = resolve(process.cwd(), 'docs/api/pokemon-champions-team-builder.openapi.yaml');
const openApiText = readFileSync(openApiPath, 'utf8');
for (const requiredPath of [
  '/v1/pokemon-champions/format-snapshots/{snapshotId}',
  '/v1/pokemon-champions/team-builder/build',
  '/v1/pokemon-champions/team-builder/audit',
]) {
  if (!openApiText.includes(requiredPath)) {
    console.error(`OpenAPI spec missing path: ${requiredPath}`);
    process.exit(1);
  }
}

console.log('Pokemon Champions team builder contracts validated.');
