
import fs from 'fs';
import path from 'path';

const dbPath = path.join(process.cwd(), 'contentData.json');

try {
    console.log(`Reading DB from: ${dbPath}`);
    const rawData = fs.readFileSync(dbPath, 'utf-8');
    const data = JSON.parse(rawData);
    let cleanedCount = 0;

    if (data.tv) {
        for (const showId in data.tv) {
            const show = data.tv[showId];
            if (show.seasons && show.seasons.user) {
                delete show.seasons.user;
                cleanedCount++;
                console.log(`Removed 'user' from seasons of show ID: ${showId}`);
            }
        }
    }

    if (cleanedCount > 0) {
        fs.writeFileSync(dbPath, JSON.stringify(data, null, 4), 'utf-8');
        console.log(`Successfully cleaned ${cleanedCount} entries.`);
    } else {
        console.log('No "user" keys found in seasons.');
    }

} catch (e) {
    console.error('Error cleaning DB:', e);
}
