<?php
/*=============================================================================
|| ##################################################################
||	Igor Crevar Extrafull
|| ##################################################################
||
||	Copyright		: (C) 2007-2009 Igor Crevar
||	Contact			: crewce@hotmail.com
||
||	- Extrafull and all of its source code and files are protected by Copyright Laws.
||
||	- You can not use any of the code without Igor Crevar agreement
||
||	- You may also not remove this copyright screen which shows the copyright information and credits for Extrafull (Igor Crevar).
||
||	- Igor Crevar Extrafull is NOT a FREE software
||
|| ##################################################################
=============================================================================*/
defined('CREW') or die();
class Database{
  var $connection;
  var $error;
  var $magic_quotes;
  var $query = '';
  static $dbo = null;	
	
	function __construct(){
		$this->error = 0;
		$this->connection = @mysql_connect( DB_HOST, DB_USER, DB_PASSWORD, true ); 
		if ( !$this->connection ){
			//$this->error = 1;
			echo 'Database greska:previse konekcija';
			exit(0);
		} 
		mysql_query( "SET NAMES 'utf8'", $this->connection );
		if ( !mysql_select_db( DB_NAME, $this->connection ) ){
			//$this->error = 2;
			exit(0);
		} 		
		$this->magic_quotes = get_magic_quotes_gpc();
		// Register faked "destructor" in PHP4 to close all connections we might have made
		/*if (version_compare(PHP_VERSION, '5') == -1) {
			register_shutdown_function( array(&$this, '__destruct') );
		}	*/
	}

	function __destruct()
	{
		$this->release();
	}
		
	function setQuery($query, $offset = -1, $limit = -1){	
		if ($offset >= 0){
			 $query .= ' LIMIT '.$offset;
			 if ($limit >= 0){
			 	 $query .= ','.$limit;
			 }
		}	
	  $this->query = str_replace( '#__', DB_PREFIX, $query );
	}
	
	function printQuery()
	{
		echo $this->query;
	}
	
	function &getInstance(){	
		if (self::$dbo == null){
			  self::$dbo = new Database();
		}	 
		return self::$dbo;
	}
	
	function isError(){
		return $this->error != 0;
	}
	
	function query( $query = null, $update = false ){
	  if ($query == null){
	    $query = $this->query;
	  }
	  else{
	  	$query = str_replace( '#__', DB_PREFIX, $query );
	  }  
		if ( $update ){
			$res = mysql_query( $query, $this->connection );
			return mysql_affected_rows($this->connection);
		}
		else {
			return mysql_query( $query, $this->connection );
		}		
	}
	
	function loadResultArray($numinarray=0){
	  if ($query == null){
	    $query = $this->query;
	  }  
		$result = mysql_query( $query, $this->connection );
		if ( !$result ) {
			$this->error = 3;
			return null;
		}
		$array = array();
		while ($row = mysql_fetch_row( $result )) {
			$array[] = $row[$numinarray];
		}
		mysql_free_result( $result );
		return $array;
	}
	
	function loadObjectList( $query = null ){
	  if ($query == null){
	    $query = $this->query;
	  }  
		$result = mysql_query( $query, $this->connection );
		if ( !$result ) {
			$this->error = 3;
			return null;
		}
		$array = array();
		while ( $row = mysql_fetch_object( $result ) ) {
			$array[] = $row;
		}
		mysql_free_result( $result );
		return $array;
	}
	
	function loadObject( $query  = null){		
	  if ($query == null){
	    $query = $this->query;
	  }  
		$result = mysql_query( $query, $this->connection );
		if ( !$result ) {
			$this->error = 3;
			return null;
		}
		$ret = null;
		if ( $object = mysql_fetch_object( $result ) ) {
			$ret = $object;
		}
		mysql_free_result( $result );
		return $ret;
	}	
	
	function loadResult( $query = null ){
	  if ($query == null){
	    $query = $this->query;
	  }  
		$result = mysql_query( $query, $this->connection );
		if ( !$result ) {
			$this->error = 3;			
			return null;
		}
		$ret = null;
		if ($row = mysql_fetch_row( $result )) {
			$ret = $row[0];
		}
		mysql_free_result( $result );
		return $ret;
	}	
	
	function queryBatch(){
		$this->error = 0;
		/*if (substr($this->query,strlen($this->query) - 1) != ';'){
			$this->query .= ';';
		}*/
		$sql = 'START TRANSACTION;'.$this->query.'COMMIT';
		$sqls = explode(';',$sql);
		foreach($sqls as $sql){
			 $val = mysql_query( $sql, $this->connection );
			 if (!$val){
			 	  $val = mysql_query( 'ROLLBACK', $this->connection );
			 		$this->error = 3;
		 			break;
			 }
		}
		return $this->error == 0 ? true : false;
	}
	
	function release(){		
		$return = false;
		if ( is_resource($this->connection) ) {
			$return = mysql_close($this->connection);
			$this->connection = null;
		}
		return $return;
	}
	
	function escape( $text ){
	  return $this->getEscaped($text);
	}
	
	//zbog jooomla kompatibilnosti
	function getEscaped( $text ){
	  if ( $this->magic_quotes ) {
       $text = stripslashes( $text );
    }
    $text = mysql_real_escape_string( $text,$this->connection );
    return $text;
	}
		
	function Quote( $text ){
		return '\''.$this->escape( $text ).'\'';
	}
			
	function toDate( $date ){
		 list($day, $month, $year) = explode('.', $date);
		 return $year.'-'.$month.'-'.$day;
	}

	function fromDate( $date ){
		 list($year, $month, $day) = explode('-', $date);
		 return $day.'.'.$month.'.'.$year.'.';
	}
	
}