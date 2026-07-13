<div align="center">

# 🛡️ UseToll

### The most efficient anti-bot filter powered by Proof of Work (PoW)

[![Demo](https://img.shields.io/badge/Live-Demo-blueviolet?style=for-the-badge)](https://demo.usetoll.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://ghcr.io/usetoll/proxy)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Stop bots without CAPTCHAs. No tracking. No friction. Just physics.**

[Live Demo](https://demo.usetoll.com) • [Quick Start](#-quick-start) • [How It Works](#-how-it-works) • [Docs](#-documentation)

</div>

---

## 💡 The Idea

Online, bots behave like humans. Distinguishing them by behavior alone has become nearly impossible.

But humans differ in **one crucial way**: they browse on real devices with powerful graphics hardware (GPU) — laptops, phones, tablets. Bots run on headless CPU servers.

**UseToll turns this asymmetry into a shield.**

It asks each visitor to solve a Proof of Work challenge that is:

- ⚡ **Blazing fast** on modern GPUs (invisible to real users)
- 🐌 **Painfully slow** on the standard CPUs bots rely on

No cookies. No fingerprinting. No annoying puzzles. Just an economic wall that makes bot traffic **prohibitively expensive**.

## ✨ Features

- 🚀 **Zero-friction** — legitimate users never see a challenge
- 🔒 **Privacy-first** — no tracking, no personal data, no third parties
- 🐳 **Drop-in proxy** — protect any site in seconds
- 🎯 **GPU-based PoW** — leverages hardware asymmetry between humans and bots
- 📦 **Self-hosted** — you own your infrastructure and your data

## 🧪 Try It Live

See how UseToll performs in the real world:

👉 **[demo.usetoll.com](https://demo.usetoll.com)**

## 🚀 Quick Start

The fastest way to get running is with the official Docker image:

```shell
docker run ghcr.io/usetoll/proxy \
  -e PORT=8080 \
  -e TARGET=https://site.to.protect
```