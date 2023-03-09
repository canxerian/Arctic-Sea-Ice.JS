const Jimp = require("jimp");
const path = require("path");

const monthPrefixes = [
    "01_Jan",
    "02_Feb",
    "03_Mar",
    "04_Apr",
    "05_May",
    "06_Jun",
    "07_Jul",
    "08_Aug",
    "09_Sep",
    "10_Oct",
    "11_Nov",
    "12_Dec",
];

const startYear = 1979;
const endYear = 2023;
const tempImgPath = path.resolve(__dirname, 'temp.png');

const getUrl = (monthPrefix, year) => {
    const monthNumber = monthPrefix.substring(0, 2);
    return `https://masie_web.apps.nsidc.org/pub/DATASETS/NOAA/G02135/north/monthly/images/${monthPrefix}/N_${year}${monthNumber}_conc_v3.0.png`
};

const downloadImageAndProcess = async (url) => {
    try {
        const image = await Jimp.read(url);
        image.write(tempImgPath);
    }
    catch (e) {
        console.error(e);
    }
}

const downloadImages = async () => {
    for (let i = startYear; i <= endYear; i++) {
        for (let j = 0; j < monthPrefixes.length; j++) {
            const monthPrefix = monthPrefixes[j];
            const url = getUrl(monthPrefix, i);

            await downloadImageAndProcess(url);
            return;
        }
    }
}

downloadImages();