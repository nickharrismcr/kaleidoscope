
import 'dart:math';
import 'package:pixi_dart/pixi.dart';

class Kaleido {

  int id, rw, rh, w, h, x, y, i,leaves, size, maxsize, btex_x, btex_y;
  double speedx,speedy,xscale,yscale;
  bool maximised;
  static int kc=0;

  BaseTexture base_texture;
  Texture texture, full_texture;
  Rectangle tex_rect, full_tex_rect;
  DisplayObjectContainer smallkal, fullkal;
  Sprite sprite;
  Stage stage;

  Kaleido(p_texture, window, p_stage ,  posx, posy, p_size, p_leaves,p_speed) {

    kc++;
    id=kc;
    stage=p_stage;
    base_texture = p_texture;
    btex_x = base_texture.width;
    btex_y = base_texture.height;
    leaves=p_leaves;
    size=p_size;
    maxsize=window.innerWidth/1.7;
    maximised=false;

    texture=new Texture(base_texture);
    full_texture=new Texture(base_texture);
    
    w = size/2;
    h = ((w * 2.0 * PI / leaves) + 3.0).toInt();

    tex_rect = new Rectangle(1,1,w,h);
    texture.setFrame(tex_rect);

    x = posx;
    y = posy;

    set_speedx(p_speed);
    set_speedy(p_speed);

    smallkal = new DisplayObjectContainer();

    for (i = 0; i < leaves; i++) {


      Sprite sprite = new Sprite(texture);
      sprite.position = new Point (x, y);
      sprite.anchor = new Point(0, 0.5);


      Graphics mymask = new Graphics();
      mymask.beginFill();
      mymask.moveTo(0, 0);
      mymask.lineTo(w, h ~/ 2);
      mymask.lineTo(w, -h ~/ 2);
      mymask.lineTo(0, 0);
      mymask.endFill();
      mymask.position.x = x;
      mymask.position.y = y;
      sprite.rotation = i * PI / (leaves / 2);
      if (i % 2 == 0) {
        sprite.scale.y = -1.0;
      }
      mymask.rotation = i * PI / (leaves / 2);

      smallkal.addChild(mymask);
      sprite.mask = mymask;
      smallkal.addChild(sprite);

    }
    
    smallkal.hitArea=new Rectangle(x-size/2,y-size/2,size,size);

    smallkal.interactive=true;
    smallkal.onClick.listen((event){resize();  });
    stage.addChild(smallkal);

    w=maxsize;
    h=((w * 2.0 * PI / leaves) + 8.0).toInt();

    rw = btex_x/2;
    rh = ((rw * 2.0 * PI / leaves) + 8.0).toInt();

    xscale=w/rw;
    yscale=h/rh;

    x = window.innerWidth/2;
    y = window.innerHeight/2;
    full_tex_rect = new Rectangle(1,1,rw,rh);
    full_texture.setFrame(full_tex_rect);
    
    fullkal = new DisplayObjectContainer();


    for (i = 0; i < leaves; i++) {

      Sprite sprite = new Sprite(full_texture);
      sprite.position = new Point (x, y);
      sprite.anchor = new Point(0, 0.5);
      sprite.scale.x=xscale;
      sprite.scale.y=yscale;

      Graphics mymask = new Graphics();
      mymask.beginFill();
      mymask.moveTo(0, 0);
      mymask.lineTo(w, h ~/ 2);
      mymask.lineTo(w, -h ~/ 2);
      mymask.lineTo(0, 0);
      mymask.endFill();
      mymask.position.x = x;
      mymask.position.y = y;
      sprite.rotation = i * PI / (leaves / 2);
      if (i % 2 == 0) {
        sprite.scale.y = -sprite.scale.y;
      }
      mymask.rotation = i * PI / (leaves / 2);

      fullkal.addChild(mymask);
      sprite.mask = mymask;
      fullkal.addChild(sprite);

    }

    fullkal.hitArea=new Rectangle(0,0,window.innerWidth, window.innerHeight);
    fullkal.interactive=true;
    fullkal.onClick.listen((event){ resize();  });

  }
  set_speedx(double speed)
  {
    speedx=speed;
  }
  set_speedy(double speed)
  {
    speedy=speed;
  }
  resize()
  {

    maximised=!maximised;
    if (maximised)
    {
       for ( var kal in stage.children )
       {
          kal.visible=false;
       }
       stage.addChild(fullkal);

    }
    else
    {
       stage.removeChild(fullkal);
       for ( var kal in stage.children )
       {
           kal.visible=true;
       }
    }
  }

  update()
  {

      if (!maximised)
      {
        tex_rect.left += speedx;
        tex_rect.top += speedy;


        if ( tex_rect.right >= btex_x - 1 )
        {
          speedx=-speedx;
          tex_rect.left-=1;
        }
        if ( tex_rect.left < 1 )
        {
          speedx=-speedx;
          tex_rect.left+=1;
        }
        if ( tex_rect.bottom >= btex_y - 1 )
        {
          speedy=-speedy;
          tex_rect.top-=1;
        }
        if ( tex_rect.top < 1 )
        {
          speedy=-speedy;
          tex_rect.top+=1;
        }
        texture.setFrame(tex_rect);
      }
      else
      {
        full_tex_rect.left += speedx;
        full_tex_rect.top += speedy;


        if ( speedx > 0 )
        {
          if ( full_tex_rect.left > btex_x/2.0)
          {
            full_tex_rect.left-=btex_x/2.0;
          }
        }
        if ( speedx < 0 )
        {
          if ( full_tex_rect.left < 0.0)
          {
            full_tex_rect.left+=btex_x/2.0;
          }
        }

        if ( full_tex_rect.bottom >= btex_y - 1 )
        {
          speedy=-speedy;
          full_tex_rect.top-=1;
        }
        if ( full_tex_rect.top < 1 )
        {
          speedy=-speedy;
          full_tex_rect.top+=1;
        }
        full_texture.setFrame(full_tex_rect);
      }

  }
}