# Fixture: Markdown Badges (rule 1)

[![English](https://img.shields.io/badge/lang-English-blue.svg)](#english)
[![한국어](https://img.shields.io/badge/lang-한국어-red.svg)](#한국어)

---

<a id="english"></a>

# English

## Overview

A bilingual document that follows the writing-style-guide. The bad-*.md fixtures each break one rule of it.

## Usage

```bash
# Check a document
python3 plugins/project-init/scripts/check-bilingual.py README.md
```

### Layout

```text
docs/
├── architecture.md   # System design
└── decisions/        # Architecture decision records
```

## Architecture

```mermaid
flowchart LR
  A([Author]) --> B[check-bilingual.py]
  B --> C[(Report)]
```

## Options

| Option | Meaning |
|--------|---------|
| `FILE` | Document to check |
| `--help` | Show the rules |

---

<a id="korean"></a>

# 한국어

## 개요

writing-style-guide를 따르는 이중언어 문서입니다. bad-*.md 픽스처는 각각 규칙 하나를 어깁니다.

## 사용법

```bash
# 문서 검사
python3 plugins/project-init/scripts/check-bilingual.py README.md
```

### 구조

```text
docs/
├── architecture.md   # 시스템 설계
└── decisions/        # 아키텍처 결정 기록
```

## 아키텍처

```mermaid
flowchart LR
  A([Author]) --> B[check-bilingual.py]
  B --> C[(Report)]
```

## 옵션

| 옵션 | 의미 |
|------|------|
| `FILE` | 검사할 문서 |
| `--help` | 규칙 표시 |
