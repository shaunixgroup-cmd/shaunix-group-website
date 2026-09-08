const fs = require('fs');
const path = require('path');

// Configuration
const config = {
    sourceDir: '/home/c2m/Desktop/official_hosted_websites/shaunix-group-website-master',
    outputFile: 'all_files_data.txt',
    fileExtensions: ['.js', '.css', '.html', '.json', '.txt', '.md'], // Empty array = all files
    excludeDirs: ['node_modules', '.git', 'dist', 'build', 'coverage'],
    maxFileSize: 5 * 1024 * 1024, // Skip files larger than 5MB
    showProgress: true,
    includeFileMetadata: true // Add file size, modified date etc.
};

function getAllFiles(dirPath, arrayOfFiles = []) {
    try {
        const files = fs.readdirSync(dirPath);

        files.forEach(file => {
            const fullPath = path.join(dirPath, file);
            const stat = fs.statSync(fullPath);

            // Skip excluded directories
            if (stat.isDirectory()) {
                if (!config.excludeDirs.includes(file)) {
                    arrayOfFiles = getAllFiles(fullPath, arrayOfFiles);
                }
                return;
            }

            // Filter by file extension if specified
            const ext = path.extname(file).toLowerCase();
            if (config.fileExtensions.length > 0 && !config.fileExtensions.includes(ext)) {
                return;
            }

            // Skip large files
            if (stat.size > config.maxFileSize) {
                return;
            }

            arrayOfFiles.push(fullPath);
        });
    } catch (error) {
        console.error(`Error reading directory ${dirPath}:`, error);
    }

    return arrayOfFiles;
}

function collectFileData(filePath) {
    try {
        const stats = fs.statSync(filePath);
        const content = fs.readFileSync(filePath, 'utf8');

        let data = '';

        if (config.includeFileMetadata) {
            data += `📁 File: ${filePath}\n`;
            data += `📊 Size: ${(stats.size / 1024).toFixed(2)} KB\n`;
            data += `📅 Modified: ${stats.mtime.toLocaleString()}\n`;
            data += `📝 Lines: ${content.split('\n').length}\n`;
            data += '─'.repeat(80) + '\n\n';
        }

        data += content;
        return data;
    } catch (error) {
        return `⚠️ Error reading file ${filePath}: ${error.message}`;
    }
}

function processFiles() {
    console.log('🚀 Starting file scan...');
    console.log(`📂 Source: ${config.sourceDir}`);

    const allFiles = getAllFiles(config.sourceDir);
    console.log(`📄 Found ${allFiles.length} files to process.`);

    if (allFiles.length === 0) {
        console.log('⚠️ No files found matching criteria.');
        return;
    }

    console.log('📖 Reading file contents...');
    let outputData = '';
    let processedCount = 0;

    allFiles.forEach(filePath => {
        outputData += `=== FILE: ${filePath} ===\n`;
        outputData += collectFileData(filePath);
        outputData += '\n\n' + '='.repeat(80) + '\n\n';
        processedCount++;

        if (config.showProgress && processedCount % 50 === 0) {
            console.log(`⏳ Processed ${processedCount}/${allFiles.length} files...`);
        }
    });

    // Write to output file
    const outputPath = path.join(config.sourceDir, config.outputFile);
    try {
        fs.writeFileSync(outputPath, outputData, 'utf8');
        console.log(`\n✅ Success! Output saved to: ${outputPath}`);
        console.log(`📊 Total files processed: ${processedCount}`);
        console.log(`📏 Output file size: ${(fs.statSync(outputPath).size / 1024 / 1024).toFixed(2)} MB`);
    } catch (error) {
        console.error('❌ Error writing output file:', error);
    }
}

// Run the script
processFiles();