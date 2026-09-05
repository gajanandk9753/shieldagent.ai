const mongoose = require("mongoose");
const vendorAgentModel = require("../../models/authModels/vendorAgent.model");

async function getVendorCatalog(req,res){
     try{
        if(req.agentRole !== 'buyer-agent'){
            return res.status(403).json({
                message: "Forbidden: Only buyer agents can browse catalogs",
                success: false
            });
        }

        const { vendorId } = req.query;

        if(!vendorId){
            return res.status(400).json({
                message: "vendorId query parameter is required",
                success: false
            });
        }

        if(!mongoose.isValidObjectId(vendorId)){
            return res.status(400).json({
                message: "Invalid vendorId format",
                success: false
            });
        }

        const vendor = await vendorAgentModel.findById(vendorId).select("companyName catalog status reputationScore");

        if(!vendor){
            return res.status(404).json({
                message: "Vendor not found",
                success: false
            });
        }

        return res.status(200).json({
            message : "Catalog fetched successfully",
            success : true,
            vendor : {
                _id : vendor._id,
                companyName : vendor.companyName,
                status : vendor.status,
                reputationScore: vendor.reputationScore
            },
            catalog : vendor.catalog
        });
    }catch(error){
        console.error("Error in getVendorCatalog:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = {
    getVendorCatalog
}