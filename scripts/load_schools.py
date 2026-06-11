#!/usr/bin/env python3
"""
전국 고등학교 목록을 NEIS 오픈API에서 받아 Supabase schools 테이블에 적재합니다.

사용법:
  pip install requests
  python3 load_schools.py --key YOUR_NEIS_API_KEY

NEIS API 키 발급 (무료, 즉시):
  1. https://open.neis.go.kr/portal/guide/apiRegisterInfo.do 접속
  2. 회원가입 → 로그인 → 인증키 신청 → 즉시 발급
  3. python3 load_schools.py --key 발급받은키
"""

import argparse, sys, time
import requests

NEIS_URL  = "https://open.neis.go.kr/hub/schoolInfo"
SUPA_URL  = "https://dwzrgzobiqhrqxjxteyu.supabase.co/rest/v1/schools"
SUPA_KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJnem9iaXFocnF4anh0ZXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwODQ1NzksImV4cCI6MjA5NjY2MDU3OX0.rBYkRaeGwDiabAX1odEgVMRD-tECfHxtiO2VOI4HJmI"

ATPT_CODES = [
    ("B10","서울특별시"), ("C10","부산광역시"), ("D10","대구광역시"),
    ("E10","인천광역시"), ("F10","광주광역시"), ("G10","대전광역시"),
    ("H10","울산광역시"), ("I10","세종특별자치시"), ("J10","경기도"),
    ("K10","강원도"),    ("M10","충청북도"),   ("N10","충청남도"),
    ("P10","전라북도"),  ("Q10","전라남도"),   ("R10","경상북도"),
    ("S10","경상남도"),  ("T10","제주특별자치도"),
]


def fetch_all(api_key: str) -> list[dict]:
    """시도교육청별로 전체 고등학교를 수집 (API 키 필요)"""
    schools: list[dict] = []

    for code, region in ATPT_CODES:
        page = 1
        while True:
            params = {
                "KEY": api_key,
                "Type": "json",
                "pIndex": page,
                "pSize": 1000,
                "SCHUL_KND_SC_NM": "고등학교",
                "ATPT_OFCDC_SC_CODE": code,
            }
            try:
                r = requests.get(NEIS_URL, params=params, timeout=15)
                r.raise_for_status()
                data = r.json()
            except Exception as e:
                print(f"[오류] {region} 요청 실패: {e}", file=sys.stderr)
                break

            if "RESULT" in data:
                msg = data["RESULT"].get("MESSAGE","")
                print(f"[NEIS 오류] {region}: {msg}", file=sys.stderr)
                break

            if "schoolInfo" not in data:
                break

            rows = data["schoolInfo"][1]["row"]
            total = data["schoolInfo"][0]["head"][0]["list_total_count"]

            for row in rows:
                schools.append({
                    "name":   row["SCHUL_NM"].strip(),
                    "region": region,
                })

            if page * 1000 >= total:
                print(f"  {region}: {len(rows)}개")
                break
            page += 1
            time.sleep(0.1)

    seen = set(); unique = []
    for s in schools:
        if s["name"] not in seen:
            seen.add(s["name"]); unique.append(s)

    print(f"\n총 {len(unique)}개 수집 완료")
    return unique


def upsert(schools: list[dict]) -> None:
    headers = {
        "apikey":        SUPA_KEY,
        "Authorization": f"Bearer {SUPA_KEY}",
        "Content-Type":  "application/json",
        "Prefer":        "resolution=merge-duplicates",
    }
    BATCH = 500
    total = len(schools); done = 0
    for i in range(0, total, BATCH):
        batch = schools[i:i+BATCH]
        r = requests.post(SUPA_URL, headers=headers, json=batch, timeout=30)
        if r.status_code in (200, 201):
            done += len(batch)
            print(f"  {done}/{total} 업로드 완료...", end="\r")
        else:
            print(f"\n[업로드 오류] {r.status_code}: {r.text[:200]}", file=sys.stderr)
    print(f"\n완료: {done}/{total}개 Supabase에 적재됨")


def write_sql(schools: list[dict], path: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write("INSERT INTO public.schools (name, region) VALUES\n")
        lines = [f"  ('{s['name'].replace(chr(39), chr(39)*2)}', '{s['region'].replace(chr(39), chr(39)*2)}')"
                 for s in schools]
        f.write(",\n".join(lines))
        f.write("\nON CONFLICT (name) DO UPDATE SET region = excluded.region;\n")
    print(f"SQL 파일 저장: {path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--key", required=True, help="NEIS API 키")
    ap.add_argument("--sql-only", metavar="FILE", default="/tmp/schools_upload.sql",
                    help="SQL 파일 경로 (기본: /tmp/schools_upload.sql)")
    args = ap.parse_args()

    schools = fetch_all(args.key)
    write_sql(schools, args.sql_only)
    print(f"\n→ 이 파일을 Claude Code에 전달하면 Supabase에 자동 적재됩니다.")


if __name__ == "__main__":
    main()
