        $(function flickSet() {
            $('.flick').bind("touchstart touchmove touchend",touchHandler);
            function touchHandler(e){
                e.preventDefault();
                var touch = e.originalEvent.touches[0];
                if(e.type == "touchstart"){
                    startX = touch.pageX;
                }else if(e.type == "touchmove"){
                    diffX = touch.pageX - startX;
                }else if(e.type == "touchend"){
                    if(diffX > 50){
                        $("#prevMon").click();
                    }
                    if(diffX < -50){
                        $("#nextMon").click();
                    }
                }
            }
        });
