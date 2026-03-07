# Recommended Google Fonts for Math Mission

## Primary Font: **Orbitron**
- **Use**: Headings, titles, mission text
- **Why**: Futuristic, space-themed, geometric design perfect for a sci-fi educational game
- **Link**: https://fonts.google.com/specimen/Orbitron
- **Weights to use**: Bold (700-900) for titles, Regular (400-500) for subtitles

## Secondary Font: **Exo 2**
- **Use**: Body text, instructions, question text, UI elements
- **Why**: Modern, readable, tech-inspired sans-serif that complements Orbitron while maintaining excellent legibility
- **Link**: https://fonts.google.com/specimen/Exo+2
- **Weights to use**: Regular (400) for body, SemiBold (600) for emphasis

## Implementation Notes

1. **Download fonts**:
   - Visit each Google Fonts link above
   - Download the font families
   - Select the weights mentioned above

2. **Add to Xcode**:
   - Drag .ttf or .otf files into Xcode project
   - Add to target membership
   - Add font names to Info.plist under "Fonts provided by application"

3. **Usage in code**:
   ```swift
   // Titles
   titleLabel.font = UIFont(name: "Orbitron-Bold", size: 48)
   
   // Subtitles
   subtitleLabel.font = UIFont(name: "Orbitron-Medium", size: 24)
   
   // Body text
   bodyLabel.font = UIFont(name: "Exo2-Regular", size: 18)
   
   // Question text
   questionLabel.font = UIFont(name: "Exo2-SemiBold", size: 32)
   ```

## Color Palette
These fonts work great with the current color scheme:
- Cyan (#00FFFF) - primary accent
- White (#FFFFFF) - main text
- Dark background (#000000)
- Orange (#FF6600) - alerts/warnings
- Green (#00FF00) - success states
