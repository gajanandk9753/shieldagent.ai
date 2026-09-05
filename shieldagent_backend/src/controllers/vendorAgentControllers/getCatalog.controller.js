async function getVendorCatalog(req, res) {
    try {
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({
                message: "Forbidden: Only vendor agents can view their catalog",
                success: false
            });
        }

        return res.status(200).json({
            message: "Catalog fetched successfully",
            success: true,
            catalog: req.agent.catalog || [],
            totalItems: req.agent.catalog ? req.agent.catalog.length : 0
        });
    } catch (error) {
        console.error("Error in getVendorCatalog:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { getVendorCatalog };