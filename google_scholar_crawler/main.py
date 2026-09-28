"""Fetch the total citation count from a Google Scholar profile.

The profile page shows the summary table with class "gsc_rsb_std":
the first cell is the total number of citations, followed by the
5-year count, h-index, i10-index, etc. Only the first one is needed.
"""

import json
import os
import re
import sys
from datetime import datetime

import requests

SCHOLAR_ID = os.environ.get('GOOGLE_SCHOLAR_ID', '').strip()
PROFILE_URL = f"https://scholar.google.com/citations?user={SCHOLAR_ID}&hl=en&view_op=list_works&sortby=pubdate"

HEADERS = {
    'User-Agent': (
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    ),
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}


def fetch_citedby():
    """Return the total citation count shown on the profile page."""
    if not SCHOLAR_ID:
        raise RuntimeError('GOOGLE_SCHOLAR_ID environment variable is not set')

    resp = requests.get(PROFILE_URL, headers=HEADERS, timeout=60)
    resp.raise_for_status()

    match = re.search(r'gsc_rsb_std[^>]*>(\d+)', resp.text)
    if not match:
        raise RuntimeError(
            'Could not find the citation count (page layout changed or request blocked)'
        )
    return int(match.group(1))


def main():
    citedby = fetch_citedby()
    print(f'citedby={citedby}')

    os.makedirs('results', exist_ok=True)

    with open('results/gs_data.json', 'w') as outfile:
        json.dump(
            {
                'scholar_id': SCHOLAR_ID,
                'citedby': citedby,
                'updated': str(datetime.now()),
            },
            outfile,
            ensure_ascii=False,
            indent=2,
        )

    with open('results/gs_data_shieldsio.json', 'w') as outfile:
        json.dump(
            {'schemaVersion': 1, 'label': 'citations', 'message': f'{citedby}'},
            outfile,
            ensure_ascii=False,
        )


if __name__ == '__main__':
    sys.exit(main())
