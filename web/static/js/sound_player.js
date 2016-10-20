import mixer from './mixer';
const appDiv = document.querySelector('#app-container');
const app = Elm.Main.embed(appDiv);

function getSample(sample_file) {
  var request = new XMLHttpRequest();
  request.open('GET', sample_file, true);
  request.responseType = 'arraybuffer';
  request.onload = function() {
    mixer.decodeAudioData(request.response, function(buffer) {
        var playBuffer = buffer;
        var source  = mixer.createBufferSource();
        source.connect(mixer.destination);
        source.buffer = playBuffer;
        source.start(0);
      },
      function(e){"Error decoding sample data" + e.err});
  }
  request.send();
}

function playSound(file) {
  getSample(file);
}

app.ports.playRawSound.subscribe(function (file) {
  playSound(file);
});
