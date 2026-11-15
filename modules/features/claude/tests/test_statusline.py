import datetime
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


script = Path(__file__).resolve().parents[1] / 'statusline.sh'


def render(data):
    result = subprocess.run(
        ['bash', str(script)], input=json.dumps(data), text=True,
        capture_output=True, check=True,
        env={**os.environ, 'CLAUDE_NVIM_FLOAT': '1', 'TZ': 'UTC', 'LC_ALL': 'C'},
    )
    assert not result.stderr, result.stderr
    return re.sub(r'\x1b\[[0-9;]*m', '', result.stdout)


with tempfile.TemporaryDirectory() as directory:
    data = {'cwd': directory, 'model': {'display_name': 'Claude'}, 'session_id': 'session'}
    assert render(data) == 'Claude'
    transcript = Path(directory) / 'transcript.jsonl'
    data['transcript_path'] = str(transcript)
    assert render(data) == 'Claude'

    def response(message_id, output, **extra):
        return {
            'type': 'assistant', 'sessionId': 'session',
            'message': {'id': message_id, 'usage': {
                'input_tokens': 100, 'cache_creation_input_tokens': 300,
                'cache_read_input_tokens': 2800, 'output_tokens': output,
            }}, **extra,
        }

    rows = [response('one', 5), response('one', 100), response('two', 22),
            response('side', 999, isSidechain=True),
            response('other', 999, sessionId='other'), {'type': 'user'}]
    transcript.write_text('\n'.join(map(json.dumps, rows)) + '\n{"type":')
    assert render(data) == 'Claude · ↑6.4k ↓122'
    for ratio, expected in [(0, '0'), (0.914, '91'), (1, '100')]:
        data['prompt_cache'] = {'hit_ratio': ratio}
        assert render(data) == f'Claude · ↑6.4k ↓122 · ch {expected}%'
    data['prompt_cache'] = {'hit_ratio': None}
    assert render(data) == 'Claude · ↑6.4k ↓122'
    data['prompt_cache'] = {'hit_ratio': 0.91}

    stamp = int(datetime.datetime(2026, 9, 14, 15, 45, tzinfo=datetime.timezone.utc).timestamp())
    data.update({
        'cost': {'total_cost_usd': 0.01234},
        'context_window': {'used_percentage': 5.5, 'context_window_size': 1000000},
        'rate_limits': {'five_hour': {'used_percentage': 12, 'resets_at': stamp},
                        'seven_day': {'used_percentage': 42, 'resets_at': stamp * 1000}},
    })
    assert render(data) == 'Claude · ↑6.4k ↓122 · ch 91% · $0.012 (est) · ctx 5.5%/1m · 12% (3:45p) · 42% (Mon 3:45p)'
    data['context_window']['context_window_size'] = 200000
    assert 'ctx 5.5%/200k' in render(data)
    data['context_window']['context_window_size'] = None
    assert 'ctx 5.5% ·' in render(data)
    data['context_window']['used_percentage'] = None
    assert 'ctx' not in render(data)
    data['cost'] = {'total_cost_usd': 0}
    assert '$0.000 (est)' in render(data)
    transcript.write_text(json.dumps(response('zero', 0)) + '\n')
    assert '↑3.2k ↓0' in render(data)

print('Passed: session totals, cache hit percentages, duplicate responses, partial transcript, missing fields, cost, context size, and resets.')
