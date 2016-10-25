import mixer from './mixer';
import elmApp from "./elm_app"

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
        source.start(mixer.currentTime);
      },
      function(e){"Error decoding sample data" + e.err});
  }
  request.send();
}

function playSound(file) {
  getSample(file);
}

if(elmApp) {
  elmApp.ports.playRawSound.subscribe(function (file) {
    playSound(file);
  });
};
