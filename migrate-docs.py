#!/usr/bin/env python3
"""
Migration script to move existing documentation to Docusaurus structure.
This helps organize the existing docs into the Diataxis framework.
"""

import os
import shutil
from pathlib import Path

def categorize_documentation():
    """Categorize existing documentation files into Diataxis categories."""
    
    # Mapping of keywords to Diataxis categories
    category_keywords = {
        'tutorials': ['tutorial', 'getting started', 'step by step', 'walkthrough', 'demo'],
        'how-to': ['how to', 'guide', 'troubleshoot', 'debug', 'configure', 'setup', 'deploy'],
        'reference': ['reference', 'api', 'configuration', 'schema', 'specification', 'adr'],
        'explanation': ['explanation', 'architecture', 'design', 'concept', 'theory', 'research']
    }
    
    docs_dir = Path('/workspace/healthcare-ml-genetic-predictor/docs')
    docs_site_dir = Path('/workspace/healthcare-ml-genetic-predictor/docs-site')
    
    # Create category directories if they don't exist
    for category in category_keywords.keys():
        (docs_site_dir / category).mkdir(exist_ok=True)
    
    # Process all markdown files
    for md_file in docs_dir.rglob('*.md'):
        if md_file.is_file():
            content = md_file.read_text(encoding='utf-8').lower()
            filename = md_file.name.lower()
            
            # Determine category based on filename and content
            target_category = None
            
            for category, keywords in category_keywords.items():
                if any(keyword in filename for keyword in keywords):
                    target_category = category
                    break
                
                if any(keyword in content[:500] for keyword in keywords):  # Check first 500 chars
                    target_category = category
                    break
            
            # Default to reference if no category found
            if target_category is None:
                target_category = 'reference'
            
            # Copy file to appropriate category
            target_path = docs_site_dir / target_category / md_file.name
            shutil.copy2(md_file, target_path)
            print(f"Copied {md_file.name} to {target_category}/")

def create_sidebar():
    """Create a basic sidebar configuration for Docusaurus."""
    
    sidebar_content = """module.exports = {
  tutorialSidebar: [
    {
      type: 'category',
      label: 'Tutorials',
      items: [
        'tutorials/getting-started',
        'tutorials/local-development',
      ],
    },
    {
      type: 'category',
      label: 'How-To Guides',
      items: [
        'how-to/deploy-to-production',
        'how-to/troubleshoot-common-issues',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      items: [
        'reference/api-documentation',
        'reference/configuration',
      ],
    },
    {
      type: 'category',
      label: 'Explanation',
      items: [
        'explanation/architecture-overview',
        'explanation/design-decisions',
      ],
    },
  ],
};"""
    
    sidebar_path = Path('/workspace/healthcare-ml-genetic-predictor/docs-site/sidebars.js')
    sidebar_path.write_text(sidebar_content)
    print("Created sidebar configuration")

def main():
    print("Starting documentation migration...")
    
    # Categorize existing documentation
    categorize_documentation()
    
    # Create sidebar
    create_sidebar()
    
    print("Migration completed!")
    print("Next steps:")
    print("1. Review the categorized files in docs-site/")
    print("2. Run 'cd docs-site && npm install'")
    print("3. Run 'npm start' to view the documentation site locally")
    print("4. Commit and push to trigger GitHub Pages deployment")

if __name__ == "__main__":
    main()