var inputView;

document.addEventListener("DOMContentLoaded", function () {
  inputView = {
    
    el: {
      searchText  : document.getElementById("search-text"),
      perPage     : document.getElementById("per-page"),
      maxReq      : document.getElementById("max-req"),
      searchButton: document.getElementById("search-button"),
      photosView  : document.getElementById("photos-view")
    },
    
    getOptions: function () {
      var options = {
          text    : this.el.searchText.value,
          per_page: this.el.perPage.value
      },
      i;
      
      for (i in options) {
        if (options.hasOwnProperty(i) && options[i] === "") {
          delete options[i];
        }
      }
      
      return options;
    },
    
    getMaxConcurrentRequest: function () {
      var maxReq = this.el.maxReq.value;
      return maxReq || false;  
    },
    
    handleClick: function (e) {
      this.fire("searchclick", e);
    }
    
  };

  makePublisher(inputView);
});
