const appDiv = document.querySelector('#app-container');
const jam_id = appDiv.getAttribute("data-jam-id");
const elmApp = Elm.Main.embed(appDiv, { jam_id: jam_id });

export default elmApp;
