const jwt = require("jsonwebtoken");
require("dotenv").config();

async function authMiddleware(req,res,next){
    const authHeader = req.headers.authorization;

    if(!authHeader || !authHeader.startsWith("Bearer ")){
        return res.status(401).json({
            messahe: "No token Provided",
            success : false
        });
    }

    const token = authHeader.split(" ")[1];
    if(!token){
        return res.status(401).json({
            messahe: "No token Provided",
            success : false
        });
    }

    try{
        const decoded = jwt.verify(token, process.env.JSON_SECRET);
        req.user = decoded;
        next();
    }catch(error){
        if (error.name === "TokenExpiredError") {
            return res.status(401).json({
                success: false,
                message: "Session expired. Please log in again.",
            });
        }
        return res.status(401).json({
            success: false,
            message: "Invalid token.",
        });
    }
}

module.exports = {
    authMiddleware
}