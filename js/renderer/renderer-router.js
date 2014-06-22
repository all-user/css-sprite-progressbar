document.addEventListener("DOMContentLoaded", function () {
  renderer.addUpdater(progressbarView.makeProgressbarUpdate().bind(progressbarView));
});
