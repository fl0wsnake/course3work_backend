from backend import jwt
from backend.auth.models import User


@jwt.user_claims_loader
def add_claims_to_access_token(identity):
    user = User.query.filter(User.id == identity).first()
    return {
        'role': user.role,
        'id': user.id,
        'email': user.email
    } if user else None
