import os
from flask import Flask, request, redirect, url_for, render_template, session, flash, send_file
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from io import BytesIO
import boto3

app = Flask(__name__)
APP_SECRET_KEY = os.getenv('APP_SECRET_KEY', '')
app.secret_key = APP_SECRET_KEY

# ------------------------------------------------------------------
# 1. Configure Database (PostgreSQL)
# ------------------------------------------------------------------
# Example: postgresql://username:password@localhost:5432/your_db_name
POSTGRES_USER = os.getenv('POSTGRES_USER', '')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', '')
POSTGRES_URL = os.getenv('POSTGRES_URL', '')
POSTGRES_PORT = os.getenv('POSTGRES_PORT', '25060')
POSTGRES_DB = os.getenv('POSTGRES_DB', 'defaultdb')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_URL}:{POSTGRES_PORT}/{POSTGRES_DB}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# ------------------------------------------------------------------
# 2. User Model
# ------------------------------------------------------------------
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)

    def __repr__(self):
        return f"<User {self.username}>"

# ------------------------------------------------------------------
# 3. Initialize Database
# ------------------------------------------------------------------
# Make sure tables exist
with app.app_context():
    try:
        db.create_all()
    except:
        print("continue")

# ------------------------------------------------------------------
# 4. Configure Boto3 for DigitalOcean Spaces
# ------------------------------------------------------------------
# Set your DigitalOcean credentials and region
# Usually, you'd read these from environment variables or a config file
DO_SPACES_KEY = os.getenv('DO_SPACES_KEY', '')
DO_SPACES_SECRET = os.getenv('DO_SPACES_SECRET', '')
DO_SPACES_REGION = os.getenv('DO_SPACES_REGION', '')
DO_SPACES_ENDPOINT = f'https://{DO_SPACES_REGION}.digitaloceanspaces.com'
DO_SPACES_BUCKET = os.getenv('DO_SPACES_BUCKET', '')


s3_client = boto3.client('s3',
    region_name=DO_SPACES_REGION,
    endpoint_url=DO_SPACES_ENDPOINT,
    aws_access_key_id=DO_SPACES_KEY,
    aws_secret_access_key=DO_SPACES_SECRET
)

# Helper function to check if filename extension is an image
def is_image(filename: str) -> bool:
    extension = filename.rsplit('.', 1)[-1].lower()
    return extension in ['jpg', 'jpeg', 'png', 'gif', 'webp']

# ------------------------------------------------------------------
# 5. Routes
# ------------------------------------------------------------------

@app.route('/', methods=['GET', 'POST'])
def index():
    """
    If GET: Show the file list from DigitalOcean Spaces in a sortable/paginated table,
            along with an upload form.
    If POST: Handle file upload, then redirect back to GET.
    """
    if 'user_id' not in session:
        flash('Please log in to access Duplo File Storage.')
        return redirect(url_for('login'))

    # Handle file upload if POST
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('No file part in the request.')
            return redirect(url_for('index'))

        uploaded_file = request.files['file']
        if uploaded_file.filename == '':
            flash('No file selected.')
            return redirect(url_for('index'))

        try:
            s3_client.upload_fileobj(
                uploaded_file,
                DO_SPACES_BUCKET,
                uploaded_file.filename,
                ExtraArgs={'ACL': 'public-read'}
            )
            flash(f"File '{uploaded_file.filename}' uploaded successfully!")
        except Exception as e:
            flash(f"An error occurred: {str(e)}")

        return redirect(url_for('index'))

    # If GET: list objects
    files = []
    try:
        response = s3_client.list_objects_v2(Bucket=DO_SPACES_BUCKET)
        contents = response.get('Contents', [])
        for obj in contents:
            file_key = obj['Key']
            # Build direct URL for thumbnail if it's an image (public-read)
            file_url = f"https://{DO_SPACES_BUCKET}.{DO_SPACES_REGION}.digitaloceanspaces.com/{file_key}"
            files.append({
                'name': file_key,
                'size': obj['Size'],
                'url': file_url,
                'is_image': is_image(file_key),
            })
    except Exception as e:
        flash(f"Error listing files: {str(e)}")

    return render_template('index.html', files=files, bucket=DO_SPACES_BUCKET, region=DO_SPACES_REGION)


@app.route('/register', methods=['GET', 'POST'])
def register():
    """ Handle user registration """
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')

        # Check if the user already exists
        existing_user = User.query.filter_by(username=username).first()
        if existing_user:
            flash('Username already taken. Please choose a different one.')
            return redirect(url_for('register'))

        # Generate a password hash with 'pbkdf2:sha256'
        hashed_pw = generate_password_hash(password, method='pbkdf2:sha256')

        new_user = User(username=username, password=hashed_pw)
        db.session.add(new_user)
        db.session.commit()

        flash('Registration successful! You can now log in.')
        return redirect(url_for('login'))
    return render_template('register.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    """ Handle user login """
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')

        user = User.query.filter_by(username=username).first()
        if user and check_password_hash(user.password, password):
            session['user_id'] = user.id
            flash('You have successfully logged in.')
            return redirect(url_for('index'))
        else:
            flash('Invalid username or password.')
            return redirect(url_for('login'))
    return render_template('login.html')


@app.route('/logout')
def logout():
    """ Log out the user by clearing the session """
    session.pop('user_id', None)
    flash('You have been logged out.')
    return redirect(url_for('login'))


@app.route('/download/<path:filename>', methods=['GET'])
def download_file(filename):
    """
    Download file from DigitalOcean Spaces.
    """
    if 'user_id' not in session:
        flash('Please log in to download files.')
        return redirect(url_for('login'))

    try:
        file_obj = s3_client.get_object(Bucket=DO_SPACES_BUCKET, Key=filename)
        return send_file(
            BytesIO(file_obj['Body'].read()),
            download_name=filename,
            as_attachment=True
        )
    except Exception as e:
        flash(f"Error downloading file: {str(e)}")
        return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True, port=5000, host="0.0.0.0")
