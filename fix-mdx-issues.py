#!/usr/bin/env python3

import os
import re
import glob

def fix_mdx_issues(file_path):
    """Fix common MDX compilation issues in markdown files"""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix patterns like <2s, <7s, <30s, etc.
    content = re.sub(r'(\s)(<\d+s)(\s)', r'\1\\\2\3', content)
    
    # Fix patterns like <$0.10
    content = re.sub(r'(\s)(<\$\d+\.\d+)(\s)', r'\1\\\2\3', content)
    
    # Fix patterns like <30s (standalone)
    content = re.sub(r'(\s)(<\d+[a-zA-Z]+)(\s)', r'\1\\\2\3', content)
    
    # Fix patterns with numbers that might be interpreted as JSX
    content = re.sub(r'(\s)(\d+[a-zA-Z]+)(\s)', r'\1`\2`\3', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed MDX issues in: {file_path}")

def main():
    docs_dir = "/workspace/healthcare-ml-genetic-predictor/docs-site/docs"
    
    # Get all markdown files
    md_files = glob.glob(os.path.join(docs_dir, "*.md"))
    
    for file_path in md_files:
        fix_mdx_issues(file_path)
    
    print("MDX issues fixed for all documentation files!")

if __name__ == "__main__":
    main()