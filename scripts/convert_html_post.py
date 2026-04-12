#!/usr/bin/env python3
"""
HTML to Jekyll Post Converter
- Strips HTML shell (DOCTYPE, html, head, body tags)
- Scopes CSS selectors with a wrapper class
- Wraps body content in a scoped div
- Prepends Jekyll front matter
"""

import re
import sys
import os


def scope_css(style_content, scope_class):
    """Prefix all CSS selectors with the scope class."""
    # Handle :root
    result = style_content.replace(':root', f'.{scope_class}')

    lines = result.split('}')
    scoped_lines = []

    for line in lines:
        if '{' not in line:
            if line.strip():
                scoped_lines.append(line)
            continue

        selector_part, rule_part = line.rsplit('{', 1)

        # Handle @media queries
        if '@media' in selector_part:
            # Keep @media as-is, will scope inner selectors
            scoped_lines.append(selector_part + '{' + rule_part + '}')
            continue

        selectors = selector_part.split(',')
        scoped_selectors = []

        for sel in selectors:
            sel = sel.strip()
            if not sel:
                continue
            if sel.startswith(f'.{scope_class}'):
                scoped_selectors.append(sel)
            elif sel == '*':
                scoped_selectors.append(f'.{scope_class} *')
            elif sel == 'body':
                scoped_selectors.append(f'.{scope_class}')
            elif sel.startswith('@'):
                scoped_selectors.append(sel)
            else:
                scoped_selectors.append(f'.{scope_class} {sel}')

        if scoped_selectors:
            scoped_lines.append(', '.join(scoped_selectors) + ' {' + rule_part + '}')

    return '\n'.join(scoped_lines)


def convert(input_path, output_path, front_matter, scope_class):
    """Convert a standalone HTML file to a Jekyll-compatible post."""
    with open(input_path, 'r', encoding='utf-8') as f:
        html = f.read()

    # Extract <style> content
    style_match = re.search(r'<style>(.*?)</style>', html, re.DOTALL)
    style_content = style_match.group(1) if style_match else ''

    # Extract <body> content
    body_match = re.search(r'<body[^>]*>(.*?)</body>', html, re.DOTALL)
    body_content = body_match.group(1).strip() if body_match else ''

    # Scope CSS
    scoped_css = scope_css(style_content, scope_class)

    # Build output
    output = f"""{front_matter}

<style>
{scoped_css}
</style>

<div class="{scope_class}">
{body_content}
</div>
"""

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(output)

    return True


if __name__ == '__main__':
    if len(sys.argv) != 5:
        print("Usage: convert_html_post.py <input> <output> <front_matter> <scope_class>")
        sys.exit(1)

    convert(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
    print(f"Converted: {sys.argv[1]} -> {sys.argv[2]}")
