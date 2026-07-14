# Ron

Personal scripts and tools.

## bus76_tracker.py

Live location tracker for **NMMT Bus 76** (Panvel ⇄ Karanjade / Asudgaon).
Pulls real-time GPS data from the NMMT tracking API, checks all 6 route
variants, and prints the current stop, passed stops, upcoming stops, a
Google Maps link, and ETA at the final stop.

### Usage

```bash
python3 bus76_tracker.py
```

- Auto-retries on flaky server (3 attempts, 3s delay, 20s timeout).
- During operating hours only: **6:35 AM – 10:00 PM**.
