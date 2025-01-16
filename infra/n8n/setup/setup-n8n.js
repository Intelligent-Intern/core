const puppeteer = require('puppeteer-core');
const fs = require('fs');

const N8N_URL      = process.env.N8N_URL       || 'http://n8n:5678';
const API_KEY_FILE = '/var/n8n/api_key.txt';

async function clickButtonBySpanText(page, text) {
    await page.waitForFunction(
        (innerText) => {
            const spans = document.querySelectorAll('button span');
            return Array.from(spans).some(s => s.textContent.trim() === innerText);
        },
        { timeout: 5000 },
        text
    );

    const buttonHandle = await page.$$eval(
        'button span',
        (spans, innerText) => {
            const span = spans.find(s => s.textContent.trim() === innerText);
            return span ? span.parentElement : null;
        },
        text
    );

    if (buttonHandle) {
        // direct click via evaluate
        await page.evaluate((btn) => btn.click(), buttonHandle);
    }
}

async function setupN8n() {
    const browser = await puppeteer.launch({
        executablePath: '/usr/bin/chromium-browser',
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    const page = await browser.newPage();

    await page.goto(`${N8N_URL}/setup`, { waitUntil: 'domcontentloaded' });

    await new Promise(r => setTimeout(r, 3000));

    // Fill out fields
    await page.type('input[name="email"]', process.env.N8N_USER_EMAIL || '');
    await page.type('input[name="password"]', process.env.N8N_USER_PASSWORD || '');
    await page.type('input[name="firstName"]', process.env.N8N_USER_FIRSTNAME || '');
    await page.type('input[name="lastName"]', process.env.N8N_USER_LASTNAME || '');

    // Submit
    await page.click('button[data-test-id="form-submit-button"]');
    await new Promise(r => setTimeout(r, 1500));

    const content = await page.content();
    console.log('PAGE CONTENT:\n', content);

    await browser.close();


    // // "Get started"
    // await clickButtonBySpanText(page, 'Get started');
    // await new Promise(r => setTimeout(r, 1000));
    //
    // // "Skip"
    // await clickButtonBySpanText(page, 'Skip');
    // await new Promise(r => setTimeout(r, 1000));
    //
    // await browser.close();
}

async function createAndStoreApiKey() {
    const browser = await puppeteer.launch({
        executablePath: '/usr/bin/chromium-browser',
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    const page = await browser.newPage();

    // Navigate to the API settings page
    await page.goto(`${N8N_URL}/settings/api`, { waitUntil: 'domcontentloaded' });
    await new Promise(r => setTimeout(r, 3000));

    // "Create an API Key"
    await clickButtonBySpanText(page, 'Create an API Key');
    await new Promise(r => setTimeout(r, 500));

    // Grab the API key
    const apiKeyElement = await page.$('[data-test-id="copy-input"] span');
    const apiKey = await page.evaluate(el => el.textContent.trim(), apiKeyElement);

    fs.writeFileSync(API_KEY_FILE, apiKey, 'utf8');
    console.log(`API Key saved to: ${API_KEY_FILE}`);

    await browser.close();
}

(async () => {
    try {
        await setupN8n();
        await createAndStoreApiKey();
        console.log('Done.');
    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
})();
