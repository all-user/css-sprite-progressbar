exports = this

document.addEventListener('DOMContentLoaded', ->
  exports.photosView =
    el :
      photosView : document.getElementById('photos-view')

    appended : []

    getAppended : ->
      return this.appended

    appendPhotos : (imgArr) ->
      return unless imgArr?
      return if imgArr.length is 0

      frag = document.createDocumentFragment()
      sent = imgArr.sent

      for v, i in imgArr
        this.appended[sent[i]] = yes
        frag.appendChild(v)

      this.el.photosView.appendChild(frag)


    clear : ->
      view = this.el.photosView
      while view.firstChild
        view.firstChild.onload = null
        view.removeChild(view.firstChild)
      this.appended = []
)
