Origami origami;

// 400x300, P3Dモードですよー。
void setup() {
  size(400, 300, P3D);
  noStroke();
  
  origami = new Origami(50, 50, 0);
}

void draw() {
  background(30);
  lights();
  
  float angle = 0.3 * radians(frameCount);
  camera(100, 100, 100,
           0,   0,   0, 
           0,  -1,   0);
  rotateY(angle);
    
  origami = origami.update();
}

class Origami {
  private float _width;
  private float _height;
  
  private float _angle;
  private int   _count;
  private int   _direction;
  
  private float _scale;
  
  Origami(float w, float h, int dir) {
    // サイズを設定
    _width  = w;
    _height = h;
    
    // 紙を開く方向を設定
    _direction = dir;
    
    // カウンタを0クリア
    _count  = 0;
    
    _scale  = dir % 2 == 0 ? 1 : 0.75;
  }
  
  // 更新
  Origami update() {
    _angle = radians(_count);

    int sign = _direction < 2 ? -1 : 1;    
    pushMatrix();
    
    // 紙が画面からはみ出ないように、さりげなくスケーリングを適用する。
    float newScale = _scale - _count * 0.25f / 180.0f;
    scale(newScale);
    
    // 注視点が常に重心を追尾するよう再計算を行い並進移動する。
    float offsetX = _direction % 2 == 0 ? sign * _angle / PI * _width : 0;
    float offsetZ = _direction % 2 == 0 ? 0 : sign * _angle / PI * _height;
    translate(offsetX, 0, offsetZ);
    
    // 二枚の折り重なる紙を描く。
    for(int i : new int[]{0, 1}) {
      pushMatrix();
      
      // うち1枚目だけは、紙を折り開くアニメーションのために並進 + 回転運動を適用する。
      if(i % 2 == 0) {
        offsetX = _direction % 2 == 0 ? sign * _width : 0;
        offsetZ = _direction % 2 == 0 ? 0 : sign * _height;

        translate(-offsetX, 0, -offsetZ);
        if (_direction % 2 == 0) 
          rotateZ(sign * _angle);
        else
          rotateX(-sign * _angle);
        translate(offsetX, 0, offsetZ);
      }
      
      // 紙はbox()関数で。
      // これを使うとlights()が有効になる。
      box(_width * 2, 0.2, _height * 2);
      popMatrix();
    }
    popMatrix();
    
    // 遷移制御。
    if(++_count < 180) return this;
    
    // 180度パタンと開いたら、次の状態へ遷移する。
    float newWidth  = _direction % 2 == 0 ? 2 *_width : _width / 2;
    float newHeight = _height;
    return new Origami(newWidth, newHeight, ++_direction % 4);
  }
}
