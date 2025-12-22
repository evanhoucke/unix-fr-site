(function () {
  if (window.location.hostname === "unix-fr.org") {
    var target = "https://www.unix-fr.org" + window.location.pathname + window.location.search + window.location.hash;
    window.location.replace(target);
  }
})();
