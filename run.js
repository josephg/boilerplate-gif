#!/usr/bin/env node

inputFilename = process.argv[2];
if (inputFilename == '-h') {
  console.error("Usage: boil-gif input.json [output.gif]");
  process.exit(1);
}

makeGif = require('./makegif');
outputFilename = makeGif(inputFilename || process.stdin, {output:process.argv[3]}, function(err, output) {
  if (err)
    console.error(err.stack);
  else
    console.log("Made " + output);
});

