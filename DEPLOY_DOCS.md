# Deploying OpenAIKit Documentation to GitHub Pages

This guide explains how to deploy the OpenAIKit documentation, including interactive tutorials, to GitHub Pages.

## Quick Start

1. **Enable GitHub Pages in your repository:**
   - Go to Settings → Pages
   - Under "Build and deployment", select "GitHub Actions" as the source
   - Save the settings

2. **Push to main branch:**
   ```bash
   git add .
   git commit -m "Add DocC documentation and GitHub Pages workflow"
   git push origin main
   ```

3. **Monitor the deployment:**
   - Go to Actions tab in your repository
   - Watch the "Deploy DocC to GitHub Pages" workflow
   - Once complete, your documentation will be available at:
     `https://marcusziade.github.io/OpenAIKit/`

## Documentation Features

The deployed site includes:

### 📖 API Documentation
- Complete API reference for all public types
- Code examples and usage guidelines
- Platform availability indicators

### 🎓 Interactive Tutorials
Navigate through 9 comprehensive tutorials:
- Setting Up OpenAIKit
- Your First Chat Completion
- Working with Functions
- Handling Errors
- Building Conversations
- Streaming Responses
- Generating Images
- Transcribing Audio
- Building Semantic Search

### 🔍 Search Functionality
- Full-text search across all documentation
- Quick navigation to any symbol or article

### 📱 Responsive Design
- Works on desktop, tablet, and mobile
- Native DocC viewer experience

## Workflow Details

The GitHub Actions workflow:

1. **Triggers on:**
   - Push to main/master branch
   - Manual workflow dispatch

2. **Build Process:**
   - Uses latest stable Xcode on macOS 14
   - Builds the Swift package
   - Generates static documentation
   - Creates redirect index page

3. **Deployment:**
   - Uploads documentation as Pages artifact
   - Deploys to GitHub Pages environment

## Customization

### Change the Base URL

If your repository has a different name, update the workflow:

```yaml
--hosting-base-path YourRepoName
```

### Custom Domain

To use a custom domain:

1. Add a `CNAME` file to the `docs` folder in the workflow:
   ```yaml
   - name: Add CNAME
     run: echo "docs.yourdomain.com" > ./docs/CNAME
   ```

2. Configure DNS settings with your domain provider

### Theme Customization

DocC uses Apple's default theme. To add custom styling:

1. Create a `theme-settings.json` file
2. Pass it to the documentation build command:
   ```bash
   --theme-url path/to/theme-settings.json
   ```

## Manual Build

To build and preview locally:

```bash
# Build documentation
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target OpenAIKit \
  --output-path ./docs \
  --transform-for-static-hosting \
  --hosting-base-path OpenAIKit

# Preview locally
python3 -m http.server 8000 --directory ./docs
# Visit http://localhost:8000
```

## Troubleshooting

### Workflow Fails

1. **Check Xcode version:**
   - Ensure your code is compatible with the latest Xcode
   - You can specify a specific version in the workflow

2. **Missing dependencies:**
   - Run `swift package resolve` locally
   - Commit `Package.resolved`

3. **Build errors:**
   - Test documentation build locally first
   - Check for missing images or code files

### Pages Not Updating

1. **Check deployment status:**
   - Go to Settings → Pages
   - Look for deployment status

2. **Clear cache:**
   - GitHub Pages caches aggressively
   - Try hard refresh (Ctrl+Shift+R or Cmd+Shift+R)

3. **Check base path:**
   - Ensure `--hosting-base-path` matches your repository name

### Broken Links

1. **Verify all tutorial resources exist:**
   ```bash
   ls -la Sources/OpenAIKit/OpenAIKit.docc/Resources/
   ```

2. **Check image references:**
   - All images must be in PNG format
   - Filenames are case-sensitive

## Best Practices

1. **Version your documentation:**
   - Tag releases with documentation updates
   - Consider branch-based documentation

2. **Test before deploying:**
   - Build documentation locally
   - Verify all tutorials work

3. **Monitor analytics:**
   - Use GitHub Pages analytics
   - Track popular documentation sections

4. **Keep tutorials updated:**
   - Update code examples with API changes
   - Refresh screenshots for new UI

## Alternative Hosting

While GitHub Pages works great, you can also host on:

- **Netlify**: Auto-deploy from GitHub
- **Vercel**: Fast global CDN
- **AWS S3**: Static website hosting
- **Your own server**: Nginx/Apache

The generated `docs` folder is completely static and portable.