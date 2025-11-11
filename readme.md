# Secure Boot with Microwatt

A work-in-progress project demonstrating a **minimal secure boot flow** using the open-source **Microwatt POWER CPU** and **SHA-256 hardware**.
The system verifies firmware integrity before execution — outputting `BOOT OK` for a valid payload and `BOOT FAIL` for a tampered one.
This is **not a completed project**, but an prototype developed for the **Microwatt Momentum Hackathon (2025)**.

## Overview

Microwatt — an open-source POWER ISA core by **Anton Blanchard (IBM/OpenPOWER Foundation)** — is paired with a **SHA-256 core by Danny Savory** for hash-based firmware validation.  
The firmware runs bare-metal on Microwatt and interacts with the SHA engine via a Wishbone interface.

## Quick Start

```bash
make docker
make hex
make sim
```

## Credits

- **Microwatt:** [Anton Blanchard](https://github.com/antonblanchard/microwatt)  
- **SHA-256 Core:** [Danny Savory](https://github.com/dsaves/SHA-256)
