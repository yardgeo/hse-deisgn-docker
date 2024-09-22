from flask import Flask, render_template, request, redirect, url_for
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__, template_folder="templates")

# Database
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ['DATABASE_URI']
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False  # silence the deprecation warning

db = SQLAlchemy(app, engine_options={'connect_args': {
    'sslmode': 'require',
    'host': os.environ['DATABASE_HOSTS'],
    'port': 6432,
    'target_session_attrs': 'read-write',
}})

# Модель для заказа
class Order(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    time = db.Column(db.String(100), nullable=False)
    location = db.Column(db.String(100), nullable=False)
    executor = db.Column(db.String(100), nullable=True)

    def __repr__(self):
        return f'<Order {self.name}>'

# Главная страница с формой для создания заказа и списком заказов
@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'create_order':
            # Создание нового заказа
            name = request.form.get('name')
            time = request.form.get('time')
            location = request.form.get('location')
            new_order = Order(name=name, time=time, location=location)
            db.session.add(new_order)
            db.session.commit()
        elif action == 'take_order':
            # Взять заказ в работу
            order_id = int(request.form.get('order_id'))
            executor = request.form.get('executor')
            order = Order.query.get(order_id)
            if order:
                order.executor = executor
                db.session.commit()
        return redirect(url_for('index'))

    orders = Order.query.all()
    return render_template('index.html', orders=orders)

if __name__ == '__main__':
    # Создаем таблицы, если их еще нет
    with app.app_context():
        db.create_all()
    
    app.run(debug=True, host='0.0.0.0', port=80)
