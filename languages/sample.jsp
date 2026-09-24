<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%-- Orders index; `orders` and `user` come from the servlet. --%>
<!DOCTYPE html>
<html>
<head><title><c:out value="${user.name}" /> — Orders</title></head>
<body>
  <h1>Orders for <c:out value="${user.name}" /></h1>
  <c:choose>
    <c:when test="${empty orders}">
      <p class="muted">No orders yet.</p>
    </c:when>
    <c:otherwise>
      <table>
        <c:forEach var="order" items="${orders}" varStatus="row">
          <tr class="${order.paid ? 'paid' : 'open'}">
            <td>#${order.number}</td>
            <td><fmt:formatNumber value="${order.total}" type="currency" /></td>
            <td><fmt:formatDate value="${order.placedAt}" pattern="yyyy-MM-dd" /></td>
          </tr>
        </c:forEach>
      </table>
    </c:otherwise>
  </c:choose>
  <% int year = java.time.Year.now().getValue(); %>
  <footer>&copy; <%= year %> Example Ltd</footer>
</body>
</html>
