# Fixture: Edge Cases That Must Pass

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a> <a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

## Inline Mentions

Markdown badges such as `[![English](badge.svg)](#english)` are named here only inside inline code. Old diagrams used `┌─┐│└─┘▶▼`; the test runner prints ✓ and → as plain text symbols.

<!--
## Hidden Heading
A multi-line comment is not part of the structure.
-->

## Nested Fences

````markdown
## Not a Heading

```bash
echo "inner fence"
```
````

## List With Code

1. Create a branch.
   ```bash
   git checkout -b feat/example
   ```
2. Open a pull request.

---

<a id="korean"></a>

# 한국어

## 인라인 언급

`[![English](badge.svg)](#english)` 같은 Markdown 배지는 인라인 코드 안에서만 언급합니다. 예전 다이어그램은 `┌─┐│└─┘▶▼`를 썼고, 테스트 러너는 ✓와 →를 일반 텍스트 기호로 출력합니다.

## 중첩 펜스

````markdown
## Not a Heading

```bash
echo "inner fence"
```
````

## 코드가 있는 목록

1. 브랜치를 만듭니다.
   ```bash
   git checkout -b feat/example
   ```
2. Pull Request를 엽니다.
