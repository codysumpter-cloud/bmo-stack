#!/usr/bin/env node
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const requiredFiles = [
  'docs/CAPABILITY_MODEL.md',
  'config/contracts/skill-package.schema.json',
  'config/contracts/app-package.schema.json',
  'config/contracts/buddy-binding.schema.json',
  'config/contracts/installed-package.schema.json',
];

const requiredKinds = {
  'config/contracts/skill-package.schema.json': 'skill-package',
  'config/contracts/app-package.schema.json': 'app-package',
  'config/contracts/buddy-binding.schema.json': 'buddy-binding',
  'config/contracts/installed-package.schema.json': 'installed-package',
};

for (const file of requiredFiles) {
  const fullPath = resolve(process.cwd(), file);
  if (!existsSync(fullPath)) {
    console.error(`Missing required capability contract file: ${file}`);
    process.exit(1);
  }
}

for (const [file, expectedKind] of Object.entries(requiredKinds)) {
  const fullPath = resolve(process.cwd(), file);
  const parsed = JSON.parse(readFileSync(fullPath, 'utf8'));
  if (parsed.type !== 'object') {
    console.error(`${file} must declare type=object`);
    process.exit(1);
  }
  if (!parsed.properties || parsed.properties.kind?.const !== expectedKind) {
    console.error(`${file} must lock kind.const=${expectedKind}`);
    process.exit(1);
  }
}

console.log('Capability contracts validated.');
