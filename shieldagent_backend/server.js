const app = require("./src/app");
require('dotenv').config();
const connectDatabase = require("./src/db/db");

const PORT = process.env.PORT || 3000;

connectDatabase();

app.listen(PORT, () => {
    console.log(`Sever started running on : ${PORT}`);
});