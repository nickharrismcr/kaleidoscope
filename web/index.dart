import 'dart:html';
import 'dart:math';
import 'dart:js';
import 'package:pixi_dart/pixi.dart';
import 'kaleido.dart';

const int LEAVES=32;

class Kaleidoscopes {

  Stage  stage;
  Renderer renderer;
  double count = 0.0, xspeed=0.6,yspeed=0.6, hue_speed=1.0;
  int i, j, k, size, x, y, xcount, ycount, images=8;

  bool webgl_supported=true, hue_shift=false, show_gui=true, loaded=false;

  List<Kaleido> kal_list;
  Kaleido kal;
  List<BaseTexture> tex_list;
  Float32List colorMatrix;
  ColorMatrixFilter filter;
  Map<int,bool> keysdown = new Map<int,bool>();
  DisplayObjectContainer   help_container, help_button, kal_container;
  Storage localstorage = window.localStorage;
  int leaves=LEAVES;


  Kaleidoscopes() {

    var canvas = querySelector("#canv");
    WebGLRenderingContext gl = canvas.getContext("webgl");
    if (gl == null) {
      webgl_supported = false;
    }

    stage = new Stage(new Color(0x000000));
    kal_container = new DisplayObjectContainer();
    kal_list = new List<Kaleido>();

    var l = localstorage['leaves'];
    if (l != null) {
      leaves = int.parse(l);
    }

    // cache textures
    tex_list = new List<BaseTexture>();

    for (k = 1; k <= images ; k++) {
      var filename = "m" + k.toString() + ".jpg";
      BaseTexture tex = new BaseTexture.fromImage(filename);
      tex_list.add(tex);
      var n = k;
      tex.source.onLoad.listen((_) {
        add_kal(leaves,n);
        querySelector("#start").innerHtml+="<p>Loaded image $n</p>";
      });
    }

    tex_list.last.source.onLoad.listen((_) {
      stage.addChild(kal_container);
      add_renderer();
      add_gui();
      loaded = true;
      window.animationFrame.then(animate);
    });
  }
  add_renderer()
  {
    if (webgl_supported)
    {
      filter = new ColorMatrixFilter();
      stage.filters = hue_shift ? [filter] : null;
      renderer = new Renderer.autoDetect(width: window.innerWidth, height:window.innerHeight);
    }
    else
    {
      renderer = new CanvasRenderer(width: window.innerWidth, height:window.innerHeight);
    }

    renderer.view.style.position = 'absolute';
    renderer.view.style.top = '0px';
    renderer.view.style.left = '0px';
    document.body.append(renderer.view);

    window.onKeyDown.listen(handleKeyDown);
    window.onKeyUp.listen(handleKeyUp);

  }
  //-----------------------------------------------------------------------------------------
  add_gui()
  {
    var jsObject;
    var controller;
    var gui = new JsObject(context['dat']['GUI']);

    jsObject = new JsObject.jsify({
      'x': this.leaves
    });
    controller = gui.callMethod('add', [jsObject, 'x', 16, 64 ]);
    controller.callMethod('name', ['Leaves']);
    controller.callMethod('step', [ 4 ]);
    controller.callMethod('onFinishChange' ,  [ (value) {
       change_leaves(value.toInt() );
       }]);

    jsObject = new JsObject.jsify({
      'x': this.xspeed
    });
    controller = gui.callMethod('add', [jsObject, 'x', -2.0, 2.0 ]);
    controller.callMethod('name', ['Speed x']);
    controller.callMethod('step', [ 0.1 ]);
    controller.callMethod('onFinishChange' ,  [ (value) {
      set_speedx(value.toDouble());
    }]);

    jsObject = new JsObject.jsify({
      'y': this.yspeed
    });
    controller = gui.callMethod('add', [jsObject, 'y', 0.0, 2.0 ]);
    controller.callMethod('name', ['Speed y']);
    controller.callMethod('step', [ 0.1 ]);
    controller.callMethod('onFinishChange' ,  [ (value) {
      set_speedy(value.toDouble());
    }]);

    if (webgl_supported) {
      jsObject = new JsObject.jsify([hue_shift]);
      controller = gui.callMethod('add', [jsObject, '0']);
      controller.callMethod('name', ['Hue Shift']);
      controller.callMethod('onChange', [(_) => toggle_hue_shift() ]);

      jsObject = new JsObject.jsify({
        'x': this.hue_speed
      });
      controller = gui.callMethod('add', [jsObject, 'x', 0.1, 6.0 ]);
      controller.callMethod('name', ['Hue shift speed']);
      controller.callMethod('step', [ 0.1 ]);
      controller.callMethod('onFinishChange' ,  [ (value) {
        hue_speed=value.toDouble();
      }]);
    }


    help_container= make_help_container();
    stage.addChild(help_container);

    help_button=make_help_button();
    stage.addChild(help_button);

  }
  //-----------------------------------------------------------------------------------------
  void add_kal(int leaves, int num) {

    size = window.innerWidth ~/ 4;

    i=num%4;
    j=(num-1)~/4;

    x = i * size + size ~/ 2;
    y = j * size + size ~/ 2;
    k = (k == 7) ? 0 : k + 1;
    kal = new Kaleido(tex_list[num-1], window, kal_container, x, y, size * 0.85, leaves, 0.6);
    kal_list.add(kal);

  }
  //-----------------------------------------------------------------------------------------
  void set_speedx(double _speed)
  {
    for (kal in kal_list) {
      kal.set_speedx(_speed);
    }
  }
  void set_speedy(double _speed)
  {
    for (kal in kal_list) {
      kal.set_speedy(_speed);
    }
  }
  //-----------------------------------------------------------------------------------------
  void animate(num value) {

    if (loaded)
    {
      count += 0.01;
      for (kal in kal_list) {
        kal.update();
      }
      if (hue_shift) {
        setHue(stage.filters[0].matrix, count*hue_speed);
      }
      renderer.render(stage);
    }

    window.animationFrame.then(animate);
  }
  //-----------------------------------------------------------------------------------------
  void change_leaves(int leaves)
  {
      localstorage['leaves']=leaves.toString();
      window.location.assign(window.location.href);
  }

  //-----------------------------------------------------------------------------------------
  void toggle_help()
  {
    help_container.visible = !help_container.visible;
    help_button.children[1].text=( help_container.visible ? "X":"?");
  }
  //-----------------------------------------------------------------------------------------

  //-----------------------------------------------------------------------------------------
  DisplayObjectContainer make_help_button()
  {
    var rect = new Graphics();
    rect.moveTo(0,0);
    var col=new Color(0x303030);
    rect.beginFill(col);
    rect.drawRect(0,0,20,20);
    rect.endFill();

    var style = new TextStyle();
    style.font="15px Arial";
    style.fill="white";

    var text = new Text("?", style);
    text.position.x=4;
    text.position.y=0.0;

    rect.interactive=true;
    rect.buttonMode=true;
    rect.hitArea=rect.getBounds();
    rect.onClick.listen(([Event]) {toggle_help();});

    var cont = new DisplayObjectContainer();
    cont.addChild(rect);
    cont.addChild(text);
    return cont;
  }
  //-----------------------------------------------------------------------------------------
  void toggle_hue_shift()
  {
    hue_shift=!hue_shift;
    stage.filters = hue_shift ? [filter] : null;
  }
  //-----------------------------------------------------------------------------------------
  void setHue(Float32List colorMatrix, double rotation)
  {
    var mcos = cos(rotation);
    var msin = sin(rotation);
    var lumR = 0.313, // or 0.3086
    lumG = 0.415, // or 0.6094
    lumB = 0.082; // or 0.0820

    colorMatrix[0] = lumR + mcos * (1 - lumR) + msin * (-lumR);
    colorMatrix[1] = lumG + mcos * (-lumG) + msin * (-lumG);
    colorMatrix[2] = lumB + mcos * (-lumB) + msin * (1 - lumB);
    colorMatrix[3] = 0.0;
    colorMatrix[4] = lumR + mcos * (-lumR) + msin * (0.143) ;
    colorMatrix[5] = lumG + mcos * (1 - lumG) + msin * (0.140) ;
    colorMatrix[6] = lumB + mcos * (-lumB) + msin * (-0.283) ;
    colorMatrix[7] = 0.0;
    colorMatrix[8] =  lumR + mcos * (-lumR) + msin * (-(1 - lumR)) ;
    colorMatrix[9] = lumG + mcos * (-lumG) + msin * (lumG);
    colorMatrix[10] = lumB + mcos * (1 - lumB) + msin * (lumB) ;
    colorMatrix[11] = 0.0;
    colorMatrix[12] = 0.0;
    colorMatrix[13] = 0.0;
    colorMatrix[14] = 0.0;
    colorMatrix[15] = 1.0;

  }
  //-----------------------------------------------------------------------------------------
  DisplayObjectContainer make_help_container()
  {
    var help_container = new DisplayObjectContainer();

    var style = new TextStyle();
    style.font="13px Arial";
    style.fill="white";

    var rect = new Graphics();
    rect.moveTo(0,0);
    var col=new Color(0x303030);
    rect.beginFill(col);
    rect.drawRect(0,0,300,100);
    rect.endFill();
    rect.position.x=0;
    rect.position.y=35;
    var text = new Text("\n* Click on a kaleidoscope to enlarge it\n\n"+
    "* H hides/shows GUI"
    , style);
    rect.addChild(text);

    help_container.addChild(rect);
    help_container.visible=false;

    rect.onClick.listen(([Event]) {toggle_help(); });

    return help_container;

  }
  //-----------------------------------------------------------------------------------------
  void toggle_gui()
  {
    show_gui = ! show_gui;
    help_button.visible=show_gui;
  }
  //-----------------------------------------------------------------------------------------
  bool key_pressed(int key)
  {
    if (! keysdown.containsKey(key))
    {
      return false;
    }
    return keysdown[key];
  }
  //-----------------------------------------------------------------------------------------
  void handleKeyDown(KeyboardEvent e)
  {
    if (e.keyCode==32 && ! key_pressed(32) )
    {
      toggle_hue_shift();
    }
    if (e.keyCode==72 && ! key_pressed(72) )
    {
      toggle_gui();
    }
    keysdown[e.keyCode ]=true;
  }
  //-----------------------------------------------------------------------------------------
  void handleKeyUp(e)
  {
    keysdown[e.keyCode ]=false;
  }
}
//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------

void main() {

  new Kaleidoscopes();
  window.onResize.listen( ([event]) => window.location.assign(window.location.href));
}

