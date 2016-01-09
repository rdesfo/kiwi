<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:exslt="http://exslt.org/common"
        exclude-result-prefixes="exslt"
>

<xsl:import href="convert14to20.xsl"/>
<xsl:import href="convert20to24.xsl"/>
<xsl:import href="convert24to35.xsl"/>
<xsl:import href="convert35to37.xsl"/>
<xsl:import href="convert37to38.xsl"/>
<xsl:import href="convert38to39.xsl"/>
<xsl:import href="convert39to41.xsl"/>
<xsl:import href="convert41to42.xsl"/>
<xsl:import href="convert42to43.xsl"/>
<xsl:import href="convert43to44.xsl"/>
<xsl:import href="convert44to45.xsl"/>
<xsl:import href="convert45to46.xsl"/>
<xsl:import href="convert46to47.xsl"/>
<xsl:import href="convert47to48.xsl"/>
<xsl:import href="convert48to49.xsl"/>
<xsl:import href="convert49to50.xsl"/>
<xsl:import href="convert50to51.xsl"/>
<xsl:import href="convert51to52.xsl"/>
<xsl:import href="convert52to53.xsl"/>
<xsl:import href="convert53to54.xsl"/>
<xsl:import href="convert54to55.xsl"/>
<xsl:import href="convert55to56.xsl"/>
<xsl:import href="convert56to57.xsl"/>
<xsl:import href="convert57to58.xsl"/>
<xsl:import href="convert58to59.xsl"/>
<xsl:import href="convert59to60.xsl"/>
<xsl:import href="convert60to61.xsl"/>
<xsl:import href="convert61to62.xsl"/>
<xsl:import href="pretty.xsl"/>


<xsl:output encoding="utf-8"/>

<xsl:template match="/">
    <xsl:variable name="v14">
        <xsl:apply-templates select="/" mode="conv14to20"/>
    </xsl:variable>

    <xsl:variable name="v20">
        <xsl:apply-templates select="exslt:node-set($v14)" mode="conv20to24"/>
    </xsl:variable>

    <xsl:variable name="v35">
        <xsl:apply-templates select="exslt:node-set($v20)" mode="conv24to35"/>
    </xsl:variable>

    <xsl:variable name="v37">
        <xsl:apply-templates select="exslt:node-set($v35)" mode="conv35to37"/>
    </xsl:variable>

    <xsl:variable name="v38">
        <xsl:apply-templates select="exslt:node-set($v37)" mode="conv37to38"/>
    </xsl:variable>

    <xsl:variable name="v39">
        <xsl:apply-templates select="exslt:node-set($v38)" mode="conv38to39"/>
    </xsl:variable>

    <xsl:variable name="v41">
        <xsl:apply-templates select="exslt:node-set($v39)" mode="conv39to41"/>
    </xsl:variable>

    <xsl:variable name="v42">
        <xsl:apply-templates select="exslt:node-set($v41)" mode="conv41to42"/>
    </xsl:variable>

    <xsl:variable name="v43">
        <xsl:apply-templates select="exslt:node-set($v42)" mode="conv42to43"/>
    </xsl:variable>

    <xsl:variable name="v44">
        <xsl:apply-templates select="exslt:node-set($v43)" mode="conv43to44"/>
    </xsl:variable>

    <xsl:variable name="v45">
        <xsl:apply-templates select="exslt:node-set($v44)" mode="conv44to45"/>
    </xsl:variable>

    <xsl:variable name="v46">
        <xsl:apply-templates select="exslt:node-set($v45)" mode="conv45to46"/>
    </xsl:variable>

    <xsl:variable name="v47">
        <xsl:apply-templates select="exslt:node-set($v46)" mode="conv46to47"/>
    </xsl:variable>

    <xsl:variable name="v48">
        <xsl:apply-templates select="exslt:node-set($v47)" mode="conv47to48"/>
    </xsl:variable>

    <xsl:variable name="v49">
        <xsl:apply-templates select="exslt:node-set($v48)" mode="conv48to49"/>
    </xsl:variable>

    <xsl:variable name="v50">
        <xsl:apply-templates select="exslt:node-set($v49)" mode="conv49to50"/>
    </xsl:variable>

    <xsl:variable name="v51">
        <xsl:apply-templates select="exslt:node-set($v50)" mode="conv50to51"/>
    </xsl:variable>

    <xsl:variable name="v52">
        <xsl:apply-templates select="exslt:node-set($v51)" mode="conv51to52"/>
    </xsl:variable>

    <xsl:variable name="v53">
        <xsl:apply-templates select="exslt:node-set($v52)" mode="conv52to53"/>
    </xsl:variable>

    <xsl:variable name="v54">
        <xsl:apply-templates select="exslt:node-set($v53)" mode="conv53to54"/>
    </xsl:variable>

    <xsl:variable name="v55">
        <xsl:apply-templates select="exslt:node-set($v54)" mode="conv54to55"/>
    </xsl:variable>

    <xsl:variable name="v56">
        <xsl:apply-templates select="exslt:node-set($v55)" mode="conv55to56"/>
    </xsl:variable>

    <xsl:variable name="v57">
        <xsl:apply-templates select="exslt:node-set($v56)" mode="conv56to57"/>
    </xsl:variable>

    <xsl:variable name="v58">
        <xsl:apply-templates select="exslt:node-set($v57)" mode="conv57to58"/>
    </xsl:variable>

    <xsl:variable name="v59">
        <xsl:apply-templates select="exslt:node-set($v58)" mode="conv58to59"/>
    </xsl:variable>

    <xsl:variable name="v60">
        <xsl:apply-templates select="exslt:node-set($v59)" mode="conv59to60"/>
    </xsl:variable>

    <xsl:variable name="v61">
        <xsl:apply-templates select="exslt:node-set($v60)" mode="conv60to61"/>
    </xsl:variable>

    <xsl:variable name="v62">
        <xsl:apply-templates select="exslt:node-set($v61)" mode="conv61to62"/>
    </xsl:variable>

    <xsl:apply-templates
        select="exslt:node-set($v62)" mode="pretty"
    />
</xsl:template>

</xsl:stylesheet>