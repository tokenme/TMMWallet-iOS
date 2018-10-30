function TMMWordCounter() {
    var documentClone = document.cloneNode(true);
    var article = new Readability(documentClone).parse();
    try {
        var el = document.createElement('div');
        el.innerHTML = article.content;
        var imgs = el.getElementsByTagName('img');
        var ts = 12, imgTs = 0;
        for (var i=0; i<imgs.length; i++) {
            if (ts <= 1) {
                imgTs += 3;
            } else {
                imgTs += ts;
                ts --;
            }
        }
        window.webkit.messageHandlers.TMMWordCounter.postMessage({"length": article.length, "imgTS": imgTs});
    }catch (error) {
        window.webkit.messageHandlers.TMMWordCounter.postMessage({"error": error.message});
    }
}
TMMWordCounter();
