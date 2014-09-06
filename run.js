#!/usr/bin/env node

inputFilename = process.argv[2];
if (!inputFilename) {
  console.error("Usage: boil-gif input.json [output.gif]");
  process.exit(1);
}

makeGif = require('./makegif');
outputFilename = makeGif(inputFilename, process.argv[3]);
console.log("Made " + outputFilename + " from " + inputFilename);

